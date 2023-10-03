using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CopyTexture : MonoBehaviour
{

    private Material grassMaterial;
    private Texture2D grassVisibilityTextureCopy;
    void Awake()
    {
        grassMaterial = GetComponent<Renderer>().material;
        Texture2D grassVisibilityTexture = grassMaterial.GetTexture("_GrassMap") as Texture2D;
        // copy the grass visibility texture
        grassVisibilityTextureCopy = new Texture2D(grassVisibilityTexture.width, grassVisibilityTexture.height, grassVisibilityTexture.format, true);
        Graphics.CopyTexture(grassVisibilityTexture, grassVisibilityTextureCopy);
        grassMaterial.SetTexture("_GrassMap", grassVisibilityTextureCopy);
    }

    void OnDestroy()
    {
        Destroy(grassVisibilityTextureCopy);
    }

}
