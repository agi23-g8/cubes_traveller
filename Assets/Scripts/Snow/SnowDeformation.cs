using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SnowDeformer : MonoBehaviour
{

    [SerializeField]
    private GameObject snowObject;

    [SerializeField]
    private int brushRadius = 4;

    [SerializeField]
    private int brushSmoothness = 4;

    [SerializeField]
    private float deformationIntensity = 5.0f;

    [SerializeField]
    private float deformationThreshold = 0.1f;

    private Texture2D snowMap;

    private List<float> weights;

    // Start is called before the first frame update
    void Start()
    {
        Material material = snowObject.GetComponent<Renderer>().material;
        snowMap = material.GetTexture("_SnowMap") as Texture2D;

        brushSmoothness = Mathf.Min(brushSmoothness, 7);

        if (brushSmoothness == 1)
            weights = new List<float>() { 0.3611f, 0.3195f };
        else if (brushSmoothness == 2)
            weights = new List<float>() { 0.2503f, 0.2215f, 0.1534f };
        else if (brushSmoothness == 3)
            weights = new List<float>() { 0.2146f, 0.1899f, 0.1315f, 0.0713f };
        else if (brushSmoothness == 4)
            weights = new List<float>() { 0.2024f, 0.1790f, 0.1240f, 0.0672f, 0.0285f };
        else if (brushSmoothness == 5)
            weights = new List<float>() { 0.1986f, 0.1757f, 0.1217f, 0.0660f, 0.0280f, 0.0093f };
        else if (brushSmoothness == 6)
            weights = new List<float>() { 0.1976f, 0.1749f, 0.1211f, 0.0657f, 0.0279f, 0.0093f, 0.0024f };
        else if (brushSmoothness == 7)
            weights = new List<float>() { 0.1974f, 0.1747f, 0.1210f, 0.0656f, 0.0278f, 0.0092f, 0.0024f, 0.0005f };
        else
            weights = new List<float>() { 1.0f };
    }

    // Update is called once per frame
    void Update()
    {
        // transform the position of the object to a position on the snow map  
        Vector3 position = transform.position;
        Ray ray = new Ray(position, -transform.up);

        RaycastHit hit;
        if (Physics.Raycast(ray, out hit))
        {
            // early discards if the player is too far from the cube.
            Vector3 actorToHitPoint = position - hit.point;
            if (actorToHitPoint.magnitude > deformationThreshold)
            {
                return;
            }
 
            // get the texture coordinates of the hit point
            Vector2 pixelUV = hit.textureCoord;

            // convert the texture coordinates to pixel coordinates 
            pixelUV.x *= snowMap.width;
            pixelUV.y *= snowMap.height;

            int centerX = (int)pixelUV.x;
            int centerY = (int)pixelUV.y;
            float weightX = 1.0f;
            float weightY = 1.0f;

            // set the pixels around the hit point to transparent
            for (int x = centerX - brushRadius - brushSmoothness; x < centerX + brushRadius + brushSmoothness; x++)
            {
                if (x < centerX - brushRadius || x > centerX + brushRadius)
                {
                    int xIndex = Mathf.Min(Mathf.Abs(centerX - x), weights.Count - 1);
                    weightX = weights[xIndex];
                }
                else
                {
                    weightX = 1.0f;
                }

                for (int y = centerY - brushRadius - brushSmoothness; y < centerY + brushRadius + brushSmoothness; y++)
                {
                    if (y < centerY - brushRadius || y > centerY + brushRadius)
                    {
                        int yIndex = Mathf.Min(Mathf.Abs(centerY - y), weights.Count - 1);
                        weightY = weights[yIndex];
                    }
                    else
                    {
                        weightY = 1.0f;
                    }

                    float depth = deformationIntensity * (weightX + weightY) / 2.0f;
                    Color color = snowMap.GetPixel(x, y);
                    color.r = Mathf.Max(color.r, depth);
                    snowMap.SetPixel(x, y, color);
                }
            }

            // apply the changes to the snow map
            snowMap.Apply();
        }
    }

}
