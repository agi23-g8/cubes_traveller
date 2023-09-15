using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RotationScript : MonoBehaviour
{

    // Update is called once per frame
    void Update()
    {
        // Arrow up
        if (Input.GetKey(KeyCode.I))
        {
            transform.RotateAround(transform.position, Camera.main.transform.right, Time.deltaTime * 50);
        }
        // Arrow down
        if (Input.GetKey(KeyCode.K))
        {
            transform.RotateAround(transform.position, -Camera.main.transform.right, Time.deltaTime * 50);
        }
        // Arrow left
        if (Input.GetKey(KeyCode.J))
        {
            transform.RotateAround(transform.position, Camera.main.transform.up, Time.deltaTime * 50);
        }
        // Arrow right
        if (Input.GetKey(KeyCode.L))
        {
            transform.RotateAround(transform.position, -Camera.main.transform.up, Time.deltaTime * 50);
        }
    }
}
