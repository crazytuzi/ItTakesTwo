import Rice.DebugMenus.Animation.DebugAnimationMenu;

/* This capability will log animation transitions
 * The transitions are always displayed in the animation debug menu.
 * The transitions can also be displayed on screen.
*/ 
class UDebugAnimationCapability : UHazeAnimationDebugCapability
{
	default CapabilityTags.Add(n"Debug");
	default CapabilityDebugCategory = n"Debug";

	// How many transitions to print
	default TransitionCountAmount = 10;

	// Will extend the debug information with location
	const bool bShowLocation = false;

	// Will extend the debug information with rotation
	const bool bShowRotation = true;

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		DebugValues.AddDebugSettingsFlag(n"PrintAnimTransitionToScreen", "Will make all the animation transitions show up on screen");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Owner.GetDebugFlag(n"PrintAnimTransitionToScreen"))
		{
			FHazeDebugTransitionData ActorTransitionData;
			AnimationDebug::GatherTransitionInfo(Owner, ActorTransitionData);

			FString DebugText = "";
			if(HasControl())
				DebugText += "Control Side\n";
			else
				DebugText += "Remote Side\n";
			
			DebugText += GetActorTransitionDataText(ActorTransitionData, bWithColors = false, bWithLocation = bShowLocation, bWithRotation = bShowRotation);
			PrintToScreen(Owner.GetName() + "\n" + DebugText);
		}
	}
}