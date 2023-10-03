using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GrassCutter : MonoBehaviour
{

    [SerializeField]
    private GameObject grass;

    [SerializeField]
    private float brushSize = 10f;

    [SerializeField]
    private float cutDepth = 0.1f;

    private Texture2D grassVisibilityTexture;


    // Start is called before the first frame update
    void Start()
    {
        Material grassMaterial = grass.GetComponent<Renderer>().material;
        grassVisibilityTexture = grassMaterial.GetTexture("_GrassMap") as Texture2D;
    }

    // Update is called once per frame
    void Update()
    {
        // transform the position of the player to a position on the grass texture  
        Vector3 playerPosition = transform.position;

        Ray ray = new Ray(playerPosition, -transform.up);
        RaycastHit hit;
        if (Physics.Raycast(ray, out hit))
        {
            Debug.DrawLine(ray.origin, hit.point, Color.red);

            // get the texture coordinates of the hit point
            Vector2 pixelUV = hit.textureCoord;

            // convert the texture coordinates to pixel coordinates 
            pixelUV.x *= grassVisibilityTexture.width;
            pixelUV.y *= grassVisibilityTexture.height;

            // set the pixels around the hit point to transparent
            for (int x = (int)pixelUV.x - (int)brushSize; x < (int)pixelUV.x + (int)brushSize; x++)
            {
                for (int y = (int)pixelUV.y - (int)brushSize; y < (int)pixelUV.y + (int)brushSize; y++)
                {
                    Color color = grassVisibilityTexture.GetPixel(x, y);
                    color.r = Mathf.Min(color.r, cutDepth);
                    grassVisibilityTexture.SetPixel(x, y, color);
                }
            }

            // apply the changes to the texture
            grassVisibilityTexture.Apply();
        }
    }

}
