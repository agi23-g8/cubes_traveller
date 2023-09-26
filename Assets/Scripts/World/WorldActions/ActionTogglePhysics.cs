using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Rigidbody))]
public class ActionTogglePhysics : WorldAction
{
    [SerializeField]
    private bool state = false;

    private Rigidbody rb;

    private void Start()
    {
        rb = GetComponent<Rigidbody>();
        Toggle(state);
    }

    public override void Execute()
    {
        state = !state;
        Toggle(state);
    }

    private void Toggle(bool state)
    {
        rb.isKinematic = !state;
    }
}
