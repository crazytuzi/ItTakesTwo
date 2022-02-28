import Cake.LevelSpecific.Shed.NailMine.WhackACodyComponent;

class UWhackACodyPeekCapability : UHazeCapability
{
	default CapabilityTags.Add(n"WhackACody");

	default CapabilityDebugCategory = n"WhackACody";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 105;

	AHazePlayerCharacter Player;
	UWhackACodyComponent WhackaComp;
	EWhackACodyDirection InputDir;
	FTransform HoleTransform;

	int LastIndex = -1;

	const float Offset = 50.f;
	const float PeekHeight = 150.f;
	const float ScoreFrequency = 3.f;
	const float ScoreDelay = 0.3f;

	// How long it takes for cody to peek up/down fully :)
	const float PeekUpTime = 0.25f;
	float ScoreTimer = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		WhackaComp = UWhackACodyComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (WhackaComp.WhackABoardRef == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WhackaComp.WhackABoardRef == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.TriggerMovementTransition(this, n"WhackACody");
		Player.BlockMovementSyncronization(this);

		// Select a default transform to attach to...
		SetCurrentDirection(EWhackACodyDirection::Up);
		ScoreTimer = 0.f;
		WhackaComp.PeekAlpha = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockMovementSyncronization(this);
		Player.DetachRootComponentFromParent();
		Player.StopAllSlotAnimations(BlendTime = 0.f);
		WhackaComp.WhackABoardRef.ActiveLid = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			// Switching hole using input..
			FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
			EWhackACodyDirection NewInputDir = WhackaComp.DirectionFromInput(Input);

			// If we are showing the tutorial, then force neutral InputDir
			if (WhackaComp.WhackABoardRef.MinigameState == EWhackACodyGameStates::ShowingTutorial)
				NewInputDir = EWhackACodyDirection::Neutral;

			// New target! Send over....
			if (NewInputDir != InputDir)
				NetSetInputDirection(NewInputDir);

		}

		// Update peek cooldown...
		if (WhackaComp.PeekCooldown > 0.f)
			WhackaComp.PeekCooldown -= DeltaTime;

		// Update peeking
		if (WhackaComp.WhackABoardRef.MinigameState == EWhackACodyGameStates::Countdown ||
			WhackaComp.PeekCooldown > 0.f)
		{
			// If we're counting down, or cody was hit, just always locally update towards neutral
			UpdatePeekingTowards(DeltaTime, EWhackACodyDirection::Neutral);
		}
		else
		{
			// Otherwise update towards the control side input
			UpdatePeekingTowards(DeltaTime, InputDir);
		}

		FTransform OffsetTransform;
		OffsetTransform.Location = -FVector(0.f, 0.f, Offset + PeekHeight * (1.f - WhackaComp.PeekAlpha));

		Player.RootComponent.WorldTransform = HoleTransform * OffsetTransform;

		// Do the scorey logic!
		if (HasControl())
		{
			if (WhackaComp.PeekAlpha > 0.9f)
			{
				ScoreTimer -= DeltaTime;
				if (ScoreTimer <= 0.f)
				{
					ScoreTimer += 1.f / ScoreFrequency;
					WhackaComp.WhackABoardRef.NetAddCodyScore();
				}
			}
			else
			{
				ScoreTimer = ScoreDelay;
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetSetInputDirection(EWhackACodyDirection NewInputDir)
	{
		InputDir = NewInputDir;
	}

	void UpdatePeekingTowards(float DeltaTime, EWhackACodyDirection TargetDir)
	{
		// Do the peeky logic!
		if (TargetDir != WhackaComp.CurrentDir)
		{
			WhackaComp.PeekAlpha = FMath::FInterpConstantTo(WhackaComp.PeekAlpha, 0.f, DeltaTime, 1.f / PeekUpTime);
			if (WhackaComp.PeekAlpha <= 0.f)
				SetCurrentDirection(TargetDir);
		}
		else if (WhackaComp.CurrentDir != EWhackACodyDirection::Neutral)
		{
			WhackaComp.PeekAlpha = FMath::FInterpConstantTo(WhackaComp.PeekAlpha, 1.f, DeltaTime, 1.f / PeekUpTime);
		}
	}

	void SetCurrentDirection(EWhackACodyDirection NewDir)
	{
		auto Board = WhackaComp.WhackABoardRef;
		USceneComponent AttachRoot = nullptr;
		UStaticMeshComponent Lid = nullptr;

		switch(NewDir)
		{
			case EWhackACodyDirection::Right:
				AttachRoot = Board.RightHole;
				Lid = Board.RightLid;
				break;

			case EWhackACodyDirection::Down:
				AttachRoot = Board.DownHole;
				Lid = Board.DownLid;
				break;

			case EWhackACodyDirection::Left:
				AttachRoot = Board.LeftHole;
				Lid = Board.LeftLid;
				break;

			case EWhackACodyDirection::Up:
				AttachRoot = Board.UpHole;
				Lid = Board.UpLid;
				break;
		}

		Board.ActiveLid = Lid;
		if (AttachRoot != nullptr)
		{
			HoleTransform = AttachRoot.WorldTransform;
			PlayRandomPeekAnimation();
		}

		WhackaComp.CurrentDir = NewDir;
	}

	void PlayRandomPeekAnimation()
	{
		if (WhackaComp.CodyAnims.Num() == 0)
			return;

		// Don't choose the same animation two times in a row :)
		int Index = 1;
		if (WhackaComp.CodyAnims.Num() > 1)
		{
			do
			{
				Index = FMath::RandRange(0, WhackaComp.CodyAnims.Num() - 1);
			} while(Index == LastIndex);
			LastIndex = Index;
		}

		UAnimSequence Anim = WhackaComp.CodyAnims[Index];
		Player.PlaySlotAnimation(Animation = Anim, bLoop = true, BlendTime = 0.f);

		//PrintToScreen("peek animation", 1);

	}
}