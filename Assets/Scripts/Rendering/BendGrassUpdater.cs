using UnityEngine;

public class BendGrassUpdater : MonoBehaviour
{

    [SerializeField]
    private string PositionVarName = "_Position";

    [SerializeField]
    private string RadiusVarName = "_BendRadius";

    [SerializeField]
    private float BendRadius = 0.15f;

    void Update()
    {
        // Get the object's world position
        Vector3 worldPosition = transform.position;

        // Update the shader uniform accessible from all shaders
        Shader.SetGlobalVector(PositionVarName, worldPosition);

        // Also update the uniform for the bend radius
        Shader.SetGlobalFloat(RadiusVarName, BendRadius);
    }
}
