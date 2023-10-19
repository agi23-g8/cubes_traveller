using System;
using System.Collections;
using System.Collections.Generic;
using System.Transactions;
using UnityEngine;
using UnityEngine.TextCore.Text;

public class OpenClose : MonoBehaviour
{
    private Animator mAnimator;
    bool prevState = false;

    // Start is called before the first frame update
    void Start()
    {
        mAnimator = GetComponent<Animator>();
    }

    // Update is called once per frame
    void Update()
    {

        if (mAnimator != null)
        {
            float horizontalInput = Input.GetAxis("Horizontal");
            float verticalInput = Input.GetAxis("Vertical");
            bool currentState = Mathf.Abs(horizontalInput) > 0.1 || Mathf.Abs(verticalInput) > 0.1;
            if (currentState != prevState)
            {
                if (currentState == true)
                {
                    mAnimator.SetTrigger("Walk");
                }
                else
                {
                    mAnimator.SetTrigger("Idle");
                }
            }
            prevState = currentState;

        }
    }
}
