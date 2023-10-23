using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ActionGoalScore : WorldAction
{
    public GameObject goalUI;
    public Animator goalAnim;

    public override void Execute()
    {
        Debug.Log("Goal Scored!");

        goalUI.SetActive(true);

        goalAnim.SetTrigger("GoalTrigger");

        StartCoroutine(WaitForAnimationThenHide());
    }

    private IEnumerator WaitForAnimationThenHide()
    {
        // hard coded 3.0f seconds animation length
        yield return new WaitForSeconds(3.0f);
        goalUI.SetActive(false);
    }
}
