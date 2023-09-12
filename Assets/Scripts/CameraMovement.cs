using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraMovement : MonoBehaviour
{
    private Vector2 touchStartPosition;
    public float rotationSpeed = 1.0f;
    public Transform rotationAnchor;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame

    void Update()
    {
        if (Input.touchCount == 1)
        {
            Touch touch = Input.GetTouch(0);

            switch (touch.phase)
            {
                case TouchPhase.Began:
                    touchStartPosition = touch.position;
                    break;

                case TouchPhase.Moved:
                    Vector2 touchDelta = touch.position - touchStartPosition;


                    float rotationX = -touchDelta.y * rotationSpeed * Time.deltaTime;
                    float rotationY = touchDelta.x * rotationSpeed * Time.deltaTime;

                    // Turn the camera around the anchor
                    transform.RotateAround(rotationAnchor.position, Vector3.up, rotationY);
                    transform.RotateAround(rotationAnchor.position, Vector3.right, rotationX);

                    touchStartPosition = touch.position;
                    break;
            }
        }
    }
}
