
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Input.MovementDirectionInputCapability;

class UMovementDirection2DInputCapability : UMovementDirectionInputCapability
{
	default CapabilityDebugCategory = CapabilityTags::Movement;
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			// Calculate input based on controlrotation
			FRotator ControlRotation = FRotator::ZeroRotator;
			ControlRotation.Yaw = Owner.GetControlRotation().Yaw;
			
			FVector RawInput = GetAttributeVector(AttributeVectorNames::MovementRaw);
			RawInput.X = 0.f;
			CurrentInput = ControlRotation.RotateVector(RawInput);
		}
		else
		{
			CurrentInput = GetReplicatedInput();	
		}		

		Owner.SetCapabilityAttributeVector(AttributeVectorNames::MovementDirection, CurrentInput);
		CrumbComp.SetReplicatedInputDirection(CurrentInput);

		if(IsDebugActive())
		{
			const FVector DebugLocation = Owner.GetActorLocation() + (MoveComp.WorldUp * 100.f);
			System::DrawDebugArrow(DebugLocation, DebugLocation + (CurrentInput * 200.f), 30.f, FLinearColor::LucBlue, Duration = 0.f, Thickness = 2.f);
		}
	}
};
