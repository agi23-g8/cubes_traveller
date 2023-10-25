using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class ScreenSpaceOutlines : ScriptableRendererFeature
{
    [System.Serializable]
    private class ScreenSpaceOutlineSettings
    {

        [Header("General Outline Settings")]
        public Color outlineColor = Color.black;
        [Range(0.0f, 20.0f)]
        public float outlineScale = 1.0f;

        [Header("Depth Settings")]
        [Range(0.0f, 100.0f)]
        public float depthThreshold = 1.5f;
        [Range(0.0f, 500.0f)]
        public float robertsCrossMultiplier = 100.0f;

        [Header("Normal Settings")]
        [Range(0.0f, 1.0f)]
        public float normalThreshold = 0.4f;

        [Header("Depth Normal Relation Settings")]
        [Range(0.0f, 2.0f)]
        public float steepAngleThreshold = 0.2f;
        [Range(0.0f, 500.0f)]
        public float steepAngleMultiplier = 25.0f;

    }

    [System.Serializable]
    private class PrepassTextureSettings
    {
        public RenderTextureFormat colorFormat;
        public int depthBufferBits = 16;
        public FilterMode filterMode;
        public Color backgroundColor = Color.black;
    }

    private class SeeThroughPass : ScriptableRenderPass
    {
        private Material seeThroughMaterial;
        private Material occlusionMaterial;
        private RTHandle seeThroughTarget;
        private RenderTextureDescriptor descriptor;
        private FilteringSettings seeThroughFilteringSettings;
        private FilteringSettings outlineFilteringSettings;
        private List<ShaderTagId> shaderTagIds;
        private PrepassTextureSettings prepassTextureSettings;

        public SeeThroughPass(
                RenderPassEvent renderPassEvent,
                LayerMask seeThroughLayerMask,
                LayerMask outlineLayerMask,
                PrepassTextureSettings prepassTextureSettings
        )
        {
            this.renderPassEvent = renderPassEvent;
            this.prepassTextureSettings = prepassTextureSettings;
            seeThroughFilteringSettings = new FilteringSettings(RenderQueueRange.opaque, seeThroughLayerMask);
            outlineFilteringSettings = new FilteringSettings(RenderQueueRange.opaque, outlineLayerMask);

            seeThroughMaterial = CoreUtils.CreateEngineMaterial(Shader.Find("Unlit/Color"));
            occlusionMaterial = CoreUtils.CreateEngineMaterial(Shader.Find("Unlit/Color"));

            seeThroughMaterial.SetColor("_Color", Color.white);
            occlusionMaterial.SetColor("_Color", Color.black);

            shaderTagIds = new List<ShaderTagId>
            {
                new ShaderTagId("UniversalForward"),
                new ShaderTagId("UniversalForwardOnly"),
                new ShaderTagId("LightweightForward"),
                new ShaderTagId("SRPDefaultUnlit"),
            };
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            descriptor = renderingData.cameraData.cameraTargetDescriptor;
            descriptor.colorFormat = prepassTextureSettings.colorFormat;
            descriptor.depthBufferBits = prepassTextureSettings.depthBufferBits;
            RenderingUtils.ReAllocateIfNeeded(ref seeThroughTarget, descriptor, name: "_SeeThroughTarget");
            ConfigureTarget(seeThroughTarget);
            ConfigureClear(ClearFlag.All, Color.black);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (!seeThroughMaterial)
            {
                Debug.LogError("See Through Material is null");
                return;
            }


            CommandBuffer cmd = CommandBufferPool.Get("See Through");
            using (new ProfilingScope(cmd, new ProfilingSampler("See Through")))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                seeThroughMaterial.SetColor("_Color", Color.white);
                DrawingSettings drawingSettings = CreateDrawingSettings(shaderTagIds, ref renderingData, renderingData.cameraData.defaultOpaqueSortFlags);
                drawingSettings.enableInstancing = true;
                drawingSettings.overrideMaterial = seeThroughMaterial;
                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref seeThroughFilteringSettings);

                DrawingSettings occludersSettings = drawingSettings;
                occludersSettings.overrideMaterial = occlusionMaterial;
                context.DrawRenderers(renderingData.cullResults, ref occludersSettings, ref outlineFilteringSettings);

                cmd.SetGlobalTexture("_SeeThrough", seeThroughTarget);
            }
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }


        public void ReleaseTargets()
        {
            seeThroughTarget?.Release();
        }
    }

    private class ScreenSpaceOutlinePass : ScriptableRenderPass
    {
        private Material screenSpaceOutlineMaterial;
        private RTHandle cameraColorTargetHandle;
        private RTHandle tempTarget;
        private RenderTextureDescriptor descriptor;
        private RenderTextureDescriptor normalsDescriptor;
        private readonly ScreenSpaceOutlineSettings screenSpaceOutlineSettings;
        private readonly PrepassTextureSettings normalsTextureSettings;
        private readonly List<ShaderTagId> shaderTagIds;
        private RTHandle normals;
        private Material normalsMaterial;
        private FilteringSettings filteringSettings;
        public ScreenSpaceOutlinePass(
                RenderPassEvent renderPassEvent,
                Material screenSpaceOutlineMaterial,
                ScreenSpaceOutlineSettings screenSpaceOutlineSettings,
                Material viewSpaceNormalsMaterial,
                PrepassTextureSettings viewSpaceNormalsTextureSettings,
                LayerMask outlinesLayerMask
            )
        {
            this.renderPassEvent = renderPassEvent;
            this.screenSpaceOutlineSettings = screenSpaceOutlineSettings;
            normalsTextureSettings = viewSpaceNormalsTextureSettings;
            this.screenSpaceOutlineMaterial = screenSpaceOutlineMaterial;
            normalsMaterial = viewSpaceNormalsMaterial;
            filteringSettings = new FilteringSettings(RenderQueueRange.opaque, outlinesLayerMask);

            shaderTagIds = new List<ShaderTagId>
            {
                new ShaderTagId("UniversalForward"),
                new ShaderTagId("UniversalForwardOnly"),
                new ShaderTagId("LightweightForward"),
                new ShaderTagId("SRPDefaultUnlit"),
            };
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            descriptor = renderingData.cameraData.cameraTargetDescriptor;
            descriptor.depthBufferBits = 0;
            RenderingUtils.ReAllocateIfNeeded(ref tempTarget, descriptor, name: "_TemporaryTarget");

            normalsDescriptor = renderingData.cameraData.cameraTargetDescriptor;
            normalsDescriptor.colorFormat = normalsTextureSettings.colorFormat;
            normalsDescriptor.depthBufferBits = normalsTextureSettings.depthBufferBits;
            RenderingUtils.ReAllocateIfNeeded(ref normals, normalsDescriptor, name: "View Space Normals Texture");
            ConfigureTarget(normals);
            ConfigureClear(ClearFlag.All, normalsTextureSettings.backgroundColor);
        }

        public void SetTarget(RTHandle cameraColorTargetHandle)
        {
            this.cameraColorTargetHandle = cameraColorTargetHandle;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (!screenSpaceOutlineMaterial || !normalsMaterial)
            {
                if (!screenSpaceOutlineMaterial) Debug.LogError("Screen Space Outline Material is null");
                if (!normalsMaterial) Debug.LogError("Normals Material is null");
                return;
            }

            screenSpaceOutlineMaterial.SetColor("_OutlineColor", screenSpaceOutlineSettings.outlineColor);
            screenSpaceOutlineMaterial.SetFloat("_OutlineScale", screenSpaceOutlineSettings.outlineScale);
            screenSpaceOutlineMaterial.SetFloat("_DepthThreshold", screenSpaceOutlineSettings.depthThreshold);
            screenSpaceOutlineMaterial.SetFloat("_RobertsCrossMultiplier", screenSpaceOutlineSettings.robertsCrossMultiplier);
            screenSpaceOutlineMaterial.SetFloat("_NormalThreshold", screenSpaceOutlineSettings.normalThreshold);
            screenSpaceOutlineMaterial.SetFloat("_SteepAngleThreshold", screenSpaceOutlineSettings.steepAngleThreshold);
            screenSpaceOutlineMaterial.SetFloat("_SteepAngleMultiplier", screenSpaceOutlineSettings.steepAngleMultiplier);

            CommandBuffer cmd = CommandBufferPool.Get("Screen Space Outline");
            using (new ProfilingScope(cmd, new ProfilingSampler("Screen Space Outline")))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                DrawingSettings drawingSettings = CreateDrawingSettings(shaderTagIds, ref renderingData, renderingData.cameraData.defaultOpaqueSortFlags);
                drawingSettings.overrideMaterial = normalsMaterial;
                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref filteringSettings);

                cmd.SetGlobalTexture("_SceneViewSpaceNormals", normals);

                Blitter.BlitCameraTexture(cmd, cameraColorTargetHandle, tempTarget);
                Blitter.BlitCameraTexture(cmd, tempTarget, cameraColorTargetHandle, screenSpaceOutlineMaterial, 0);

            }
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

        public void ReleaseTargets()
        {
            tempTarget?.Release();
            normals?.Release();
        }
    }

    [SerializeField] private RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
    [SerializeField] private LayerMask outlinesLayerMask;
    [SerializeField] private LayerMask seeThroughLayerMask;
    [SerializeField] private Shader viewSpaceNormalsShader;
    [SerializeField] private Shader screenSpaceOutlineShader;
    [SerializeField] private Shader transparentsShader;

    [SerializeField] private PrepassTextureSettings viewSpaceNormalsTextureSettings;

    [SerializeField] private ScreenSpaceOutlineSettings screenSpaceOutlineSettings;

    private ScreenSpaceOutlinePass screenSpaceOutlinePass;
    private SeeThroughPass seeThroughPass;
    private Material screenSpaceOutlineMaterial;
    private Material viewSpaceNormalsMaterial;

    public override void Create()
    {

        if (screenSpaceOutlineMaterial == null || screenSpaceOutlineMaterial.shader != screenSpaceOutlineShader)
        {
            Debug.Log("Creating new screen space outline material");
            if (screenSpaceOutlineMaterial != null) CoreUtils.Destroy(screenSpaceOutlineMaterial);
            screenSpaceOutlineMaterial = CoreUtils.CreateEngineMaterial(screenSpaceOutlineShader);
        }

        if (viewSpaceNormalsMaterial == null || viewSpaceNormalsMaterial.shader != viewSpaceNormalsShader)
        {
            Debug.Log("Creating new view space normals material");
            if (viewSpaceNormalsMaterial != null) CoreUtils.Destroy(viewSpaceNormalsMaterial);
            viewSpaceNormalsMaterial = CoreUtils.CreateEngineMaterial(viewSpaceNormalsShader);
        }


        screenSpaceOutlinePass = new ScreenSpaceOutlinePass(
            renderPassEvent,
            screenSpaceOutlineMaterial,
            screenSpaceOutlineSettings,
            viewSpaceNormalsMaterial,
            viewSpaceNormalsTextureSettings,
            outlinesLayerMask
        );


        seeThroughPass = new SeeThroughPass(
            renderPassEvent,
            seeThroughLayerMask,
            outlinesLayerMask,
            viewSpaceNormalsTextureSettings
        );
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        CameraType cameraType = renderingData.cameraData.cameraType;
        if (cameraType == CameraType.Preview) return;
        renderer.EnqueuePass(seeThroughPass);
        renderer.EnqueuePass(screenSpaceOutlinePass);
    }

    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
    {
        screenSpaceOutlinePass.SetTarget(renderer.cameraColorTargetHandle);
    }

    protected override void Dispose(bool disposing)
    {
        screenSpaceOutlinePass.ReleaseTargets();
        seeThroughPass.ReleaseTargets();
    }
}