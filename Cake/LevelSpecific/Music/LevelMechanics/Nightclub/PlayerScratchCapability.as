import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Music.LevelMechanics.Nightclub.Scratchboard;
import Peanuts.ButtonMash.Silent.ButtonMashSilent;
import Cake.LevelSpecific.Music.LevelMechanics.Nightclub.PlayerScratchComponent;

class UPlayerScratchCapability : UHazeCapability
{
	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	AScratchboard CurrentScratchboard = nullptr;
	UPlayerScratchComponent ScratchComp;

	FVector StartLocation;

	float ScratchScalar = 0.005f;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		ScratchComp = UPlayerScratchComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(GetAttributeObject(n"ActiveScratchboard") == nullptr)
		{
			return EHazeNetworkActivation::DontActivate;
		}

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		UObject TargetScratchBoard = GetAttributeObject(n"ActiveScratchBoard");
		ActivationParams.AddObject(n"ActiveScratchBoard", TargetScratchBoard);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		MoveComp.StopMovement();
		StartLocation = Owner.ActorLocation;
		UObject TargetObject = nullptr;
		ConsumeAttribute(n"ActiveScratchBoard", TargetObject);

		TargetObject = ActivationParams.GetObject(n"ActiveScratchBoard");
		CurrentScratchboard = Cast<AScratchboard>(TargetObject);
		devEnsure(CurrentScratchboard != nullptr, "Scratchboard is null, not cool.");
		CurrentScratchboard.InteractionComponent.Disable(n"Scratch");

		if(CurrentScratchboard.IsOutOfScratch())
		{
			CurrentScratchboard.OnStartScratching(Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(CurrentScratchboard != nullptr)
		{
			CurrentScratchboard.InteractionComponent.Enable(n"Scratch");
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(CurrentScratchboard == nullptr)
		{
			return EHazeNetworkDeactivation::DeactivateLocal;
		}

		if(CurrentScratchboard.IsOutOfScratch())
		{
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}

		if((StartLocation - Owner.ActorLocation).Size2D() > 10.0f)
		{
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl() && WasActionStarted(ActionNames::ButtonMash))
		{
			CurrentScratchboard.IncrementScratch(ScratchComp.GetScratchValue() * ScratchScalar, Player);
		}
	}
}
