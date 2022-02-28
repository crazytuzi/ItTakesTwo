import Cake.LevelSpecific.Music.MusicalChairs.MusicalChairsPlayerComponent;

class UMusicalChairsRunningCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MusicalChairs");

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 30;

	AHazePlayerCharacter Player;
	AMusicalChairsActor MusicalChairs;
	UMusicalChairsPlayerComponent MusicalChairsComp;
	UMusicalChairsPlayerComponent OtherMusicalChairsComp;
	UHazeSplineFollowComponent SplineFollowComponent;

	EMusicalChairsButtonType PressedButton;

	bool bMoveForwardOnSpline = true;

	float RunningSpeed = 350.0f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		MusicalChairsComp = UMusicalChairsPlayerComponent::Get(Owner);
		OtherMusicalChairsComp = UMusicalChairsPlayerComponent::Get(Player.OtherPlayer);
		MusicalChairs = MusicalChairsComp.MusicalChairs;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!IsActioning(n"StartMusicalChairs"))
			return EHazeNetworkActivation::DontActivate;

		if(!MusicalChairs.bMiniGameIsOn)
			return EHazeNetworkActivation::DontActivate;

		if(!MusicalChairs.bCountDownFinished)
			return EHazeNetworkActivation::DontActivate;

		if(MusicalChairs.bRoundOver)
			return EHazeNetworkActivation::DontActivate;

		if(MusicalChairs.bGameOver)
			return EHazeNetworkActivation::DontActivate;

		else
			return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(MusicalChairsComp.bPressedButton)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(MusicalChairs.bGameOver)
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		if(MusicalChairs.bRoundOver)
			return EHazeNetworkDeactivation::DeactivateLocal;
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ConsumeAction(n"StartMusicalChairs");

		// if(Player.IsMay())
		// {
		// 	Player.AttachToComponent(MusicalChairs.MayAttachComp, NAME_None, EAttachmentRule::SnapToTarget);
		// }
		// else
		// {
		// 	Player.AttachToComponent(MusicalChairs.CodyAttachComp, NAME_None, EAttachmentRule::SnapToTarget);
		// }

		if(SplineFollowComponent == nullptr)
			SplineFollowComponent = UHazeSplineFollowComponent::Get(Player);

		SplineFollowComponent.ActivateSplineMovement(MusicalChairs.FollowSpline, bMoveForwardOnSpline);

		if(OtherMusicalChairsComp == nullptr)
			OtherMusicalChairsComp = UMusicalChairsPlayerComponent::Get(Player.OtherPlayer);

		MusicalChairsComp.bRunning = true;
		MusicalChairsComp.bRequestLocomotion = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(HasControl())
		{
			if(MusicalChairsComp.bPressedButton)
				MusicalChairs.PlayerPressedButton(Player, PressedButton);
		}
		
		//Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		SplineFollowComponent.DeactivateSplineMovement();

		MusicalChairsComp.bPressedButton = false;
		MusicalChairsComp.bRunning = false;
		MusicalChairsComp.bRequestLocomotion = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UpdateSplineMovement(DeltaTime);

		bool bLeft = IsActioning(ActionNames::MinigameLeft);
		bool bRight = IsActioning(ActionNames::MinigameRight);
		bool bTop = IsActioning(ActionNames::MinigameTop);
		bool bBottom = IsActioning(ActionNames::MinigameBottom);

		if(bLeft || bRight || bTop || bBottom)
		{
			EMusicalChairsButtonType NewButtonPressed;

			if(bLeft)
			 	NewButtonPressed = EMusicalChairsButtonType::LeftFaceButton;
			else if(bRight)
			 	NewButtonPressed = EMusicalChairsButtonType::RightFaceButton;
			else if(bTop)
			 	NewButtonPressed = EMusicalChairsButtonType::TopFaceButton;
			else if(bBottom)
			 	NewButtonPressed = EMusicalChairsButtonType::BottomFaceButton;

			PressedButton = NewButtonPressed;

			MusicalChairsComp.bPressedButton = true;
			return;
		}
		
		MusicalChairsComp.bPressedButton = false;
	}


	UFUNCTION()
	void UpdateSplineMovement(float DeltaTime)
	{
		FHazeSplineSystemPosition SplinePosition;
		const float MoveAmount = RunningSpeed * DeltaTime;

		bool bWarped = false;
		const EHazeUpdateSplineStatusType UpdateStatus = SplineFollowComponent.UpdateSplineMovementAndRestartAtEnd(MoveAmount, SplinePosition, bWarped);

		if(HasControl())
		{
			Player.SetActorLocation(SplinePosition.GetWorldLocation());
			Player.SetActorRotation(SplinePosition.GetWorldRotation());
		}

	}

}