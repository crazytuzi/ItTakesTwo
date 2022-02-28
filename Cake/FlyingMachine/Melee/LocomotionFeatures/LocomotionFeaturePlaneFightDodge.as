
class UHazeLocomotionFeaturePlaneFightDodge : ULocomotionFeatureMeleeDefault
{
    default Tag = n"Dodge";

	UPROPERTY(Category = "Animation")
	float HorizontalTranslationAmount = 0;

	UPROPERTY(Category = "Animation")
	float HorizontalTranslationMoveSpeed = 0;
}