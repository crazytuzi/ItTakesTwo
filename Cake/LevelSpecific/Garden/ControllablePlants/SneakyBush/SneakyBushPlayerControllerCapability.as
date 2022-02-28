import Vino.Movement.MovementSystemTags;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.SneakyBush.SneakyBush;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Cake.LevelSpecific.Garden.MoleStealth.MoleStealthSystem;
import Vino.Tutorial.TutorialStatics;

class USneakyBushPlayerControllerCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::StickInput);
	default CapabilityTags.Add(CapabilityTags::MovementInput);

	default TickGroup = ECapabilityTickGroups::Input;
	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;

	AHazePlayerCharacter PlayerOwner;
	UControllablePlantsComponent PlantsComponent;
	ASneakyBush SneakyBush;
	UMoleStealthPlayerComponent StealthComponent;
	bool bHasBlockedExit = false;
	bool bIsShowingWidget = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		PlantsComponent = UControllablePlantsComponent::Get(PlayerOwner);
		StealthComponent = UMoleStealthPlayerComponent::Get(PlayerOwner);
		PlantsComponent.bCanExitSoil = false;
		SetBlock(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		SetBlock(false);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		ASneakyBush CurrentSneakyBush = Cast<ASneakyBush>(PlantsComponent.CurrentPlant);
		if(CurrentSneakyBush == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(SneakyBush == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		ASneakyBush CurrentSneakyBush = Cast<ASneakyBush>(PlantsComponent.CurrentPlant);
		if(SneakyBush != CurrentSneakyBush)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(IsActioning(n"ForceExitBush"))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SneakyBush = Cast<ASneakyBush>(PlantsComponent.CurrentPlant);
		StealthComponent.ActivateBush();
		StealthComponent.UpdateBushLocation(SneakyBush.GetActorLocation());
		ConsumeAction(n"ForceExitBush");
		ShowExitWidget(PlantsComponent.bCanExitSoil);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(SneakyBush != nullptr)
		{
			SneakyBush = nullptr;
			StealthComponent.DeactivateBush();
			PlayerOwner.MeshOffsetComponent.ResetLocationWithTime(0.1f);
		}

		ShowExitWidget(false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			const FVector WorldUp = PlayerOwner.GetMovementWorldUp();
			const FRotator ControlRotation = PlayerOwner.GetControlRotation();

			FVector Forward = ControlRotation.ForwardVector.ConstrainToPlane(WorldUp).GetSafeNormal();
			if (Forward.IsZero())
			{
				Forward = ControlRotation.UpVector.ConstrainToPlane(WorldUp).GetSafeNormal();
			}
			
			const FVector Right = WorldUp.CrossProduct(Forward);

			const FVector RawStick = GetAttributeVector(AttributeVectorNames::MovementRaw);
			const FVector Input = Forward * RawStick.X + Right * RawStick.Y;

			SneakyBush.SetCapabilityAttributeVector(AttributeVectorNames::MovementDirection, Input);
		}

		StealthComponent.UpdateBushLocation(SneakyBush.GetActorLocation());
		bool bMayIsInStealth = false;
		if(StealthComponent.CurrentManager != nullptr)
			bMayIsInStealth = StealthComponent.CurrentManager.GetActiveShapeCounter(EHazePlayer::May) > 0;

		bool bShouldBeBlocked = !PlantsComponent.bCanExitSoil || bMayIsInStealth;
		SetBlock(bShouldBeBlocked);
		ShowExitWidget(!bShouldBeBlocked);
	}

	void SetBlock(bool bStatus)
	{
		if(!HasControl())
			return;

		if(bHasBlockedExit == bStatus)
			return;
		
		bHasBlockedExit = bStatus;
		if(bHasBlockedExit)
			PlayerOwner.BlockCapabilities(n"ExitPlant", this);
		else
			PlayerOwner.UnblockCapabilities(n"ExitPlant", this);
	}

	void ShowExitWidget(bool bStatus)
	{
		if(!HasControl())
			return;

		if(bIsShowingWidget == bStatus)
			return;
			
		bIsShowingWidget = bStatus;
		if(bStatus)
			ShowTutorialPrompt(PlayerOwner, PlantsComponent.ExitTutorial, PlantsComponent);
		else
			RemoveTutorialPromptByInstigator(PlayerOwner, PlantsComponent);
	}
}


class UDEBUGSneakyBushForceInputCapabilityCapability : UHazeDebugCapability
{
	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 99;
	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;

	AHazePlayerCharacter PlayerOwner;

	bool bHasAutomaticMovement = false;

	float NextUpDown = 0;
	float NextRightLeft = 0;

	float MovingUp = 0;
	float MovingRight = 0;

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"SwapAutomaticMovement", "Swap Automatic Movement");
		Handler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadDown, n"SneakyBush");
	}

	UFUNCTION(NotBlueprintCallable)
	void SwapAutomaticMovement()
	{
		bHasAutomaticMovement = !bHasAutomaticMovement;
	}

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(!bHasAutomaticMovement)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}


	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!bHasAutomaticMovement)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		NextRightLeft = 0;
		NextUpDown = 0;
		MovingUp = 0;
		MovingRight = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float GameTime = Time::GetGameTimeSeconds();
		
		if(GameTime > NextRightLeft)
		{
			MovingRight = FMath::RandRange(-1.f, 1.f);
			NextRightLeft = GameTime + FMath::RandRange(0.5f, 2.f);
		}

		if(GameTime > NextUpDown)
		{
			MovingUp = FMath::RandRange(-1.f, 1.f);
			NextUpDown = GameTime + FMath::RandRange(0.5f, 2.f);
		}

		PlayerOwner.SetCapabilityAttributeVector(AttributeVectorNames::MovementRaw, FVector(MovingUp, MovingRight, 0));
	}
}