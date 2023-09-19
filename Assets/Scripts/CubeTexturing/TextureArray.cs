using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.IO;

using UnityEngine;
using UnityEngine.Serialization;

using UnityEditor;
using UnityEditor.Build;

public static class Texture2DArrayExtensions
{
    public static Texture2DArray CreateTexure2DArray(params Texture2D[] _textures)
    {
        // creates the texture array using the first texture's format
        Texture2D firstTex = _textures[0];
        var texImporter = AssetImporter.GetAtPath(AssetDatabase.GetAssetPath(firstTex)) as TextureImporter;
        bool isLinear = texImporter.textureType == TextureImporterType.NormalMap || texImporter.textureType == TextureImporterType.SingleChannel;
        bool useMipmaps = firstTex.mipmapCount > 1;

        var texArray = new Texture2DArray(
            _textures[0].width,
            _textures[0].height,
            _textures.Length,
            _textures[0].format,
            useMipmaps,
            isLinear);

        texArray.anisoLevel = _textures[0].anisoLevel;
        texArray.filterMode = _textures[0].filterMode;
        texArray.wrapMode = _textures[0].wrapMode;

        // goes over all the textures and copies pixels to array
        for (int texIndex = 0; texIndex < _textures.Length; texIndex++)
        {
            Texture2D currentTex = _textures[texIndex];

            for (int mip = 0; mip < currentTex.mipmapCount; mip++)
            {
                Graphics.CopyTexture(currentTex, 0, mip, texArray, texIndex, mip);
            }
        }

        return texArray;
    }

    public static void SetTextureProps(this Texture2D _src, int _maxSize, TextureImporterType _type, TextureImporterCompression _compression, bool _useMipmaps)
    {
        // updates texture importer settings
        var texImporter = AssetImporter.GetAtPath(AssetDatabase.GetAssetPath(_src)) as TextureImporter;
        texImporter.isReadable = false;
        texImporter.maxTextureSize = _maxSize;
        texImporter.textureCompression = _compression;
        texImporter.mipmapEnabled = _useMipmaps;
        texImporter.textureType = _type;

        // for single channel textures, uses the red channel as input
        if (_type == TextureImporterType.SingleChannel)
        {
            TextureImporterSettings settings = new TextureImporterSettings();
            texImporter.ReadTextureSettings(settings);
            settings.singleChannelComponent = TextureImporterSingleChannelComponent.Red;
            texImporter.SetTextureSettings(settings);
        }

        // disables platform specific overrides
        var platforms = new string[] {
            "Standalone", "Web", "iPhone", "Android", "WebGL", "Windows Store Apps", "PS4", "XboxOne", "Nintendo 3DS" ,"tvOS"
        };

        foreach (var platform in platforms)
        {
            var settings = texImporter.GetPlatformTextureSettings(platform);
            settings.overridden = false;
            texImporter.SetPlatformTextureSettings(settings);
        }

        texImporter.SaveAndReimport();
    }

}

[CreateAssetMenu(menuName = "Custom/TextureArray")]
public class TextureArray : ScriptableObject
{
    [SerializeField] private bool m_useMipMaps = true;
    [SerializeField] private PrettyTextureImporterType m_type = PrettyTextureImporterType.ColorMap; 
    [SerializeField] private PrettyTextureImporterCompression m_compression = PrettyTextureImporterCompression.Standard;
    [SerializeField] private MaxSize m_maxSize = MaxSize._2048;
    [SerializeField] private Material m_targetMaterial;
    [SerializeField] private string m_targetSlot = "_TextureList";
    [SerializeField] private List<Texture2D> m_textures = new List<Texture2D>();

    string m_targetPath
    {
        get
        {
            // texture array asset is saved next to the description asset
            var pathToMe = AssetDatabase.GetAssetPath(this);
            return Path.GetDirectoryName(pathToMe) + "\\" + Path.GetFileNameWithoutExtension(pathToMe) + "_GEN.asset";
        }
    }

    [ContextMenu("Build Texture Array")]
    void BuildTextureArray()
    {
        // early discards if no textures provided
        if (m_textures.Count == 0)
        {
            Debug.LogWarning("No source textures specified, texture array was not generated.");
            return;
        }

        string progressHeader = "TextureArray Generator " + name;
        EditorUtility.DisplayProgressBar(progressHeader, "", 0f);

        // setups source textures to be compatible with the user-defined array format
        for (int i = 0; i < m_textures.Count; i++)
        {
            EditorUtility.DisplayProgressBar(progressHeader, "Updating texture import settings for " + m_textures[i].name, ((float)(i + 1) / m_textures.Count));
            m_textures[i].SetTextureProps((int)m_maxSize, (TextureImporterType)m_type, (TextureImporterCompression)m_compression, m_useMipMaps);
        }

        AssetDatabase.SaveAssets();

        // builds the texture array asset
        EditorUtility.DisplayProgressBar(progressHeader, "Generating TextureArray", 0f);
        var Array = Texture2DArrayExtensions.CreateTexure2DArray(m_textures.ToArray());

        // saves the asset on disk
        EditorUtility.DisplayProgressBar(progressHeader, "Saving TextureArray", 0f);
        AssetDatabase.CreateAsset(Array, m_targetPath);
        AssetDatabase.SaveAssets();
        Debug.Log("Saved asset to " + m_targetPath);

        // loads again to use the asset in the material from disk
        EditorUtility.DisplayProgressBar(progressHeader, "Assigning TextureArray to material", 0f);
        var loaded = AssetDatabase.LoadAssetAtPath<Texture2DArray>(m_targetPath);
        m_targetMaterial.SetTexture(m_targetSlot, loaded);

        EditorUtility.ClearProgressBar();
    }

    public enum PrettyTextureImporterCompression
    {
        Standard = TextureImporterCompression.Compressed,
        LowQualityHighPerf = TextureImporterCompression.CompressedLQ,
        HighQualityLowPerf = TextureImporterCompression.CompressedHQ,
        Uncompressed = TextureImporterCompression.Uncompressed,
    }

    public enum PrettyTextureImporterType
    {
        ColorMap = TextureImporterType.Default,
        NormalMap = TextureImporterType.NormalMap,
        SingleChannelMap = TextureImporterType.SingleChannel
    }

    public enum MaxSize
    {
        _32 = 32,
        _64 = 64,
        _128 = 128,
        _256 = 256,
        _512 = 512,
        _1024 = 1024,
        _2048 = 2048,
        _4096 = 4096
    }

}
