import Vino.Movement.Components.MovementComponent;
import Peanuts.Movement.DefaultCharacterCollisionSolver;
import Peanuts.Movement.NoWallCollisionSolver;
import Peanuts.Movement.DefaultCharacterRemoteCollisionSolver;

class UFlipNoClipMovementCapability : UHazeDebugCapability
{
    default CapabilityTags.Add(CapabilityTags::Debug);
    default CapabilityTags.Add(CapabilityTags::Movement);

	bool bNoClipActive = false;

	UHazeMovementComponent MoveComp;
	TSubclassOf<UHazeCollisionSolver> LastUsedSolver;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"ToggleNoWallClip", "ToggleNoWallClip");
		Handler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadUp, n"Movement");
	}

	UFUNCTION()
	void ToggleNoWallClip()
	{
		if (!bNoClipActive)
		{
			LastUsedSolver = MoveComp.GetCollisionSolver().Class;
			MoveComp.UseCollisionSolver(UNoWallCollisionSolver::StaticClass(), UDefaultCharacterRemoteCollisionSolver::StaticClass());
		}
		else
		{
			MoveComp.UseCollisionSolver(LastUsedSolver, UDefaultCharacterRemoteCollisionSolver::StaticClass());
		}

		bNoClipActive = !bNoClipActive;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!bNoClipActive)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!bNoClipActive)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PrintToScreen("" + Owner.GetName() + " Wall collision disabled", 0.f, FLinearColor::Red);
	}
};