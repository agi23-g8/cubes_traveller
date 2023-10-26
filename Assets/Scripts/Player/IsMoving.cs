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

    public bool currentState = false;

    // Start is called before the first frame update
    void Start()
    {
        mAnimator = GetComponent<Animator>();
        mAnimator.SetBool("IsWalking", false);
    }

    // Update is called once per frame
    void Update()
    {
        if (mAnimator != null)
        {
            float horizontalInput = Input.GetAxis("Horizontal");
            float verticalInput = Input.GetAxis("Vertical");
            currentState = Mathf.Abs(horizontalInput) > 0.01 || Mathf.Abs(verticalInput) > 0.01;
            if (currentState != prevState)
            {
                if (currentState == true)
                {
                    mAnimator.SetBool("IsWalking", true);
                }
                else
                {
                    mAnimator.SetBool("IsWalking", false);
                }
            }
            prevState = currentState;

        }
    }
}
