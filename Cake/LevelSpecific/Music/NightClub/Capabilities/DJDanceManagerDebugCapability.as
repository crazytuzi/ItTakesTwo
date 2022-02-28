import Cake.LevelSpecific.Music.NightClub.DJDanceRevolutionManager;

class UDJDanceManagerDebugCapability : UHazeDebugCapability
{
	default CapabilityTags.Add(n"Debug");
	default CapabilityTags.Add(n"DebugDJDanceManager");
	default TickGroup = ECapabilityTickGroups::Input;
    default CapabilityDebugCategory = n"Debug";

	ADJDanceRevolutionManager Manager;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Manager = Cast<ADJDanceRevolutionManager>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		FHazeDebugFunctionCallHandler SkipRoundHandle = DebugValues.AddFunctionCall(n"SkipRound", "Skip Round");
		FHazeDebugFunctionCallHandler ResetRoundsHandle = DebugValues.AddFunctionCall(n"ResetRounds", "Reset Rounds");

		SkipRoundHandle.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::TriggerLeft, n"DJDance");
		ResetRoundsHandle.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::TriggerRight, n"DJDance");
	}

	UFUNCTION()
	void SkipRound()
	{
		Manager.Dev_SkipRound();
	}

	UFUNCTION()
	void ResetRounds()
	{
		Manager.Dev_ResetDJRounds();
	}
}
