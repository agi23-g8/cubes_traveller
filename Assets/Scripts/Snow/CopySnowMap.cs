using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CopySnowMap : MonoBehaviour
{
    private Material snowMaterial;
    private Texture2D snowMapCopy;
    void Awake()
    {
        snowMaterial = GetComponent<Renderer>().material;
        Texture2D snowMap = snowMaterial.GetTexture("_SnowMap") as Texture2D;

        // copy the snow map
        snowMapCopy = new Texture2D(snowMap.width, snowMap.height, snowMap.format, false, true);
        Graphics.CopyTexture(snowMap, snowMapCopy);
        snowMaterial.SetTexture("_SnowMap", snowMapCopy);
    }

    void OnDestroy()
    {
        Destroy(snowMapCopy);
    }

}
