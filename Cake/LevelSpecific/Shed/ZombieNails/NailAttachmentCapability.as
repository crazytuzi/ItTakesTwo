import Cake.LevelSpecific.Shed.ZombieNails.AttachedNailCounterComponent;
import Vino.Movement.Components.MovementComponent;
import Peanuts.ButtonMash.Progress.ButtonMashProgress;
import Peanuts.ButtonMash.ButtonMashStatics;


class NailAttachmentCapability : UHazeCapability
{
	default CapabilityTags.Add(n"ZombieNails");
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	AHazePlayerCharacter Player;
	UHazeMovementComponent Movement;
	UAttachedNailCounterComponent NailCounterComponent;
	UButtonMashProgressHandle ButtonMashHandle;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		NailCounterComponent = UAttachedNailCounterComponent::GetOrCreate(Owner);
		Movement = UHazeMovementComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (NailCounterComponent.AttachedNails.Num() >= 1)
       		return EHazeNetworkActivation::ActivateFromControl;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (NailCounterComponent.AttachedNails.Num() <= 0)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ButtonMashHandle = StartButtonMashProgressAttachToActor(Player, Player, FVector(0,0,100));
		Player.BlockCapabilities(n"Dash", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.CustomTimeDilation = 1.f;
		StopButtonMash(ButtonMashHandle);
		Player.UnblockCapabilities(n"Dash", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		CheckButtonMashRate();
		AdjustMovementSpeed();
	}

	void AdjustMovementSpeed()
	{
		float MoveSpeedModifier = 1 - (0.2f * NailCounterComponent.AttachedNails.Num());
		Player.CustomTimeDilation = MoveSpeedModifier;
	}

	void CheckButtonMashRate()
	{
		if(NailCounterComponent.AttachedNails.Num() > 0)
		{
			if(ButtonMashHandle.MashRateControlSide >= 2.f * NailCounterComponent.AttachedNails.Num())
			{
				NailCounterComponent.DecrementNails();
			}
			if(NailCounterComponent.AttachedNails.Num() > 0)
				ButtonMashHandle.Progress = ButtonMashHandle.MashRateControlSide / (2.f * NailCounterComponent.AttachedNails.Num());
		}
	}
}