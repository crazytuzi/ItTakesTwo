import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Helpers.MovementJumpHybridData;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

UCLASS(Abstract)
class UPlantJumpCapability : UCharacterMovementCapability
{
	FMovementCharacterJumpHybridData JumpData;

	UFUNCTION()
	float CalculateVerticalJumpForceWithInheritedVelocityAndApplyHorizontalVelocityAsImpulse(float VerticalJumpImpulse) const
	{
		FVector InheritedVelocity = MoveComp.GetInheritedVelocity(false);
		FVector HorizontalInherited = InheritedVelocity.ConstrainToPlane(MoveComp.WorldUp);
		float VerticalInherited = InheritedVelocity.DotProduct(MoveComp.WorldUp);

		MoveComp.AddImpulse(HorizontalInherited);
		return VerticalJumpImpulse + VerticalInherited;
	}
}
