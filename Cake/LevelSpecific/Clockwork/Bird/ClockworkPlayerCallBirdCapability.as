import Cake.LevelSpecific.Clockwork.Bird.ClockworkBird;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdFlyingComponent;
import Vino.Tutorial.TutorialStatics;

const float CALL_BIRD_MIN_DISTANCE = 6000.f;

class UClockworkPlayerCallBirdCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"CallClockworkBird");

	AHazePlayerCharacter Player;
	UClockworkBirdFlyingComponent FlyingComp;
	UHazeBaseMovementComponent MoveComp;

	AClockworkBird PreviousUsedBird;
	AClockworkBird PotentialCallBird;
	AClockworkBird CallingBird;
	bool bPromptShown = false;
	bool bIsValidating = false;

	bool bCallDone = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		FlyingComp = UClockworkBirdFlyingComponent::GetOrCreate(Player);
		MoveComp = UHazeBaseMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PotentialCallBird == nullptr)
			return EHazeNetworkActivation::DontActivate;
		if (IsActioning(CapabilityTags::Interaction))
			return EHazeNetworkActivation::DontActivate;
		if (!WasActionStarted(ActionNames::InteractionTrigger))
			return EHazeNetworkActivation::DontActivate;
		if (!MoveComp.IsGrounded())
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateFromControlWithValidation;
	}

	UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ActivationParams) const
	{
		AClockworkBird AttemptCallBird = Cast<AClockworkBird>(ActivationParams.GetObject(n"Bird"));
		if (AttemptCallBird.ActivePlayer != nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{		
		if (bCallDone)
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// Determine if we can call any bird
		if (FlyingComp.MountedBird != nullptr)
		{
			PreviousUsedBird = FlyingComp.MountedBird;
			PotentialCallBird = nullptr;
		}
		else
		{
			if (PreviousUsedBird != nullptr && PreviousUsedBird.PlayerIsUsingBird(Player.OtherPlayer))
				PreviousUsedBird = nullptr;

			if (PreviousUsedBird != nullptr)
			{
				bool bBirdFarAway = PreviousUsedBird.GetDistanceTo(Player) >= CALL_BIRD_MIN_DISTANCE;
				if (bBirdFarAway && FlyingComp.CanCallBirds.Contains(PreviousUsedBird))
					PotentialCallBird = PreviousUsedBird;
				else
					PotentialCallBird = nullptr;
			}
			else
			{
				PotentialCallBird =  nullptr;

				float MinDistance = MAX_flt;
				for (auto Bird : FlyingComp.CanCallBirds)
				{
					if (Bird.AnyPlayerIsUsingBird())
						continue;

					float Distance = Bird.GetDistanceTo(Player);
					if (Distance < MinDistance)
					{
						MinDistance = Distance;
						PotentialCallBird = Bird;
					}
				}

				if (MinDistance < CALL_BIRD_MIN_DISTANCE)
					PotentialCallBird = nullptr;
			}
		}

		// Show prompt for calling bird
		bool bShouldPrompt = !IsBlocked()
			&& PotentialCallBird != nullptr
			&& !IsActioning(CapabilityTags::Interaction)
			&& MoveComp.IsGrounded()
			&& !bIsValidating
			&& !IsActive();
		if (bShouldPrompt != bPromptShown)
		{
			if (bShouldPrompt)
			{
				FTutorialPrompt CallPrompt;
				CallPrompt.Action = ActionNames::InteractionTrigger;
				CallPrompt.DisplayType = ETutorialPromptDisplay::Action;
				CallPrompt.Text = NSLOCTEXT("ClockworkBird", "CallBirdPrompt", "Call Bird");
				ShowTutorialPrompt(Player, CallPrompt, this);
			}
			else
			{
				RemoveTutorialPromptByInstigator(Player, this);
			}
			bPromptShown = bShouldPrompt;
		}
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		bIsValidating = true;

		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		PotentialCallBird.InteractionComp.Disable(n"PlayerCalling");

		bPromptShown = false;
		RemoveTutorialPromptByInstigator(Player, this);

		OutParams.AddObject(n"Bird", PotentialCallBird);
	}

	UFUNCTION(BlueprintOverride)
	void ControlPostValidation(bool bWasValid)
	{
		bIsValidating = false;
		if (!bWasValid)
		{
			Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
			Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
			CallingBird.InteractionComp.Enable(n"PlayerCalling");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CallingBird = Cast<AClockworkBird>(ActivationParams.GetObject(n"Bird"));

		if (!HasControl())
		{
			Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
			Player.BlockCapabilities(CapabilityTags::MovementInput, this);
			CallingBird.InteractionComp.Disable(n"PlayerCalling");
		}

		bCallDone = false;
		BP_StartCall(CallingBird, Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (!bCallDone)
			CallIsFinished();
		CallingBird.InteractionComp.Enable(n"PlayerCalling");
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartCall(AClockworkBird Bird, AHazePlayerCharacter Player)
	{
		CallIsFinished();
	}

	UFUNCTION()
	void CallIsFinished()
	{
		if (bCallDone)
			return;
		bCallDone = true;

		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);

		Player.TriggerMovementTransition(this);

		AActor TeleportPosition = nullptr;
		float ClosestDistance = MAX_flt;

		for (AActor PotentialPosition : FlyingComp.CallBirdPositions)
		{
			if (PotentialPosition == nullptr)
				continue;

			float Distance = PotentialPosition.GetDistanceTo(Player);
			if (Distance < ClosestDistance)
			{
				ClosestDistance = Distance;
				TeleportPosition = PotentialPosition;
			}
		}

		if (TeleportPosition != nullptr)
			CallingBird.TeleportBirdIntoFlying(TeleportPosition.ActorLocation, TeleportPosition.ActorRotation);
		else
			CallingBird.TeleportBirdIntoFlying(Player.ActorLocation, Player.ActorRotation);

		CallingBird.ForceMountPlayer(Player);
	}
};

UFUNCTION(Category = "Clockwork Bird")
void AllowPlayerToCallClockworkBird(AHazePlayerCharacter Player, TArray<AClockworkBird> Birds)
{
	auto Comp = UClockworkBirdFlyingComponent::GetOrCreate(Player);
	Comp.CanCallBirds = Birds;
	Comp.CallBirdPositions.Empty();
}

UFUNCTION(Category = "Clockwork Bird")
void AllowPlayerToCallClockworkBirdToPositions(AHazePlayerCharacter Player, TArray<AClockworkBird> Birds, TArray<AActor> TeleportPositions)
{
	auto Comp = UClockworkBirdFlyingComponent::GetOrCreate(Player);
	Comp.CanCallBirds = Birds;
	Comp.CallBirdPositions = TeleportPositions;
}

UFUNCTION(Category = "Clockwork Bird")
void StopPlayerCallClockworkBird(AHazePlayerCharacter Player)
{
	UClockworkBirdFlyingComponent::GetOrCreate(Player).CanCallBirds.Empty();
}