
import Vino.Movement.Components.MovementComponent;

class UCharacterFaceCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::CharacterFacing);
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	// Internal Variables
	UHazeMovementComponent Movement;
	AHazeCharacter CharacterOwner;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CharacterOwner = Cast<AHazeCharacter>(Owner);
        ensure(CharacterOwner != nullptr);

		Movement = UHazeMovementComponent::GetOrCreate(CharacterOwner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TickActive(Owner.GetActorDeltaSeconds());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);
		if(!Input.IsNearlyZero())
		{
			Movement.SetTargetFacingRotation(CharacterOwner.ControlRotation);
		}

		// Debug
		if(IsDebugActive())
		{
			const FVector ActorLocation = Owner.GetActorLocation() + FVector(0.f, 0.f, 50.f);
			System::DrawDebugArrow(ActorLocation, ActorLocation + (Movement.GetTargetFacingRotation().Vector() * 100.f), 10.f, FLinearColor::Green, Thickness = 4.f);
			System::DrawDebugArrow(ActorLocation - (Owner.GetControlRotation().Vector() * 150.f), ActorLocation + (Owner.GetControlRotation().Vector() * 150.f), 10.f, FLinearColor::Blue, Thickness = 2.f);
		}
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		if(IsActive())
		{
			FString DebugText = "";
			if(HasControl())
			{
				DebugText += "Control Side\n";
				DebugText += "<Green>Current Rotation: " + Movement.GetTargetFacingRotation().ToString() + "</>\n";
				DebugText += "<Blue>Control Rotation: " + Owner.GetControlRotation().ToString() + "</>\n";
			}
			else
			{
				DebugText += "Slave Side\n";
				DebugText += "<Green>Current Rotation: " + Movement.GetTargetFacingRotation().ToString() + "</>\n";
			}
			return DebugText;
		}

		return "Not Active";
	}
};
