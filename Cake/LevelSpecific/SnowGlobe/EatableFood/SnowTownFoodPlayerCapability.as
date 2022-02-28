import Cake.LevelSpecific.SnowGlobe.EatableFood.SnowTownFood;

class USnowTownFoodPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SnowTownFoodPlayerCapability");
	default CapabilityTags.Add(n"SnowTownFood");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	ASnowTownFood SnowTownFood;

	bool bShouldRotate;

	bool bHaveEaten;

	bool bShouldDeactivate;

	UAnimSequence ChosenAnim;

	FVector Direction; 

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		bShouldDeactivate = false;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!bShouldDeactivate)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ActivationParams) const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.TriggerMovementTransition(this);

		UObject FoodPlate;
		float Value = 0.f;

		ConsumeAttribute(n"FoodPlate", FoodPlate);
		ConsumeAttribute(n"IsMirror", Value);

		SnowTownFood = Cast<ASnowTownFood>(FoodPlate);
		bHaveEaten = false;

		Direction = (SnowTownFood.ActorLocation - Player.ActorLocation).ConstrainToPlane(FVector::UpVector);
		Direction.Normalize();
		FRotator TargetRot = FRotator::MakeFromX(Direction);		
		Player.SmoothSetLocationAndRotation(Player.ActorLocation, TargetRot, 2000.f, 40.f);

		if (Player == Game::May)
		{
			if (Value == 1)
				ChosenAnim = SnowTownFood.EatingAnimationsMay1;
			else
				ChosenAnim = SnowTownFood.EatingAnimationsMay2;
		}
		else
		{
			if (Value == 1)
				ChosenAnim = SnowTownFood.EatingAnimationsCody1;
			else
				ChosenAnim = SnowTownFood.EatingAnimationsCody2;
		}

		FHazeAnimationDelegate BlendOut;
		BlendOut.BindUFunction(this, n"AnimBlendOut");
		Player.PlaySlotAnimation(FHazeAnimationDelegate(), BlendOut, ChosenAnim);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SnowTownFood.RemovePlayerCapability(Player);
	}

	UFUNCTION()
	void AnimBlendOut()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		SnowTownFood.EnableInteraction();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (bHaveEaten)
			return;

		float Dot = Direction.DotProduct(Player.ActorForwardVector);

		if (Dot >= 0.85f)
			EatFood();
	}	

	UFUNCTION()
	void EatFood()
	{
		bHaveEaten = true;
		SnowTownFood.InteractionActivated();
		System::SetTimer(this, n"ActivateShouldDeactivate", 0.2f, false);
	}

	UFUNCTION()
	void ActivateShouldDeactivate()
	{
		bShouldDeactivate = true;
	}
}