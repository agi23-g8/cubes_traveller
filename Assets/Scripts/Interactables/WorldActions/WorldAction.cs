using UnityEngine;

/// <summary>
/// The Action system lets interactables execute actions on other objects in the world.
/// Place an action on an object and then drag it to the interactable ActionOnPressed field.
/// </summary>
public abstract class WorldAction : MonoBehaviour
{
    public abstract void Execute();
}
