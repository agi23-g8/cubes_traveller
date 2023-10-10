using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LimitY : MonoBehaviour
{
    [SerializeField]
    private Transform respawnPosition;

    [SerializeField]
    private float yThreshold = -10;

    private Rigidbody rb;

    private void Start()
    {
        rb = GetComponent<Rigidbody>();
    }

    private void Update()
    {
        if (transform.position.y < yThreshold)
        {
            transform.position = respawnPosition.position;
            rb.velocity = Vector3.zero;
        }
    }
}
