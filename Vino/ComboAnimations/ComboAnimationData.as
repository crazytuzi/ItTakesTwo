
enum EComboAnimationMode
{
	SlotAnimation,
	Feature
};

enum EComboControlMode
{
	// Locked control mode means the character's facing stays the same the whole combo
	Locked,
	// Only allows the direction to be changed between animations, but stays locked within an animation
	PerAnimation,
	// Rotation is fully free and the character can rotate and move in different directions during attacks
	Free,
};

struct FComboElement
{
	/* Total duration of this combo element if not interrupted. */
	UPROPERTY(Category = "Timing")
	float Duration = 1.f;

	/* Initial duration of the combo element. Animation cannot be interrupted during this duration. */
	UPROPERTY(Category = "Timing")
	float InitialLockedDuration = 0.5f;

	/* Duration measured from the end of the combo element that it can no longer be interrupted during. If this duration is entered. */
	UPROPERTY(Category = "Timing")
	float FinalDropDuration = 0.1f;

	/* Duration into the animation (measured from the start) that the 'hit' effect is triggered. NOTE: Should always be lower than InitialLockedDuration! */
	UPROPERTY(Category = "Timing")
	float HitTiming = 0.5f;

	/* Where to source the animation to use from. */
	UPROPERTY(Category = "Animation")
	EComboAnimationMode AnimationMode = EComboAnimationMode::SlotAnimation;

	/* Slot animation to play when this combo element is active. */
	UPROPERTY(Category = "Animation", Meta = (EditCondition = "AnimationMode == EComboAnimationMode::SlotAnimation", EditConditionHides))
	UAnimSequence SlotAnimation;

	/* Animation feature to request when this combo element is active. */
	UPROPERTY(Category = "Animation", Meta = (EditCondition = "AnimationMode == EComboAnimationMode::Feature", EditConditionHides))
	FName FeatureTag = n"Combo";

	/* Sub tag to send to the animation feature when this combo element is active. */
	UPROPERTY(Category = "Animation", Meta = (EditCondition = "AnimationMode == EComboAnimationMode::Feature", EditConditionHides))
	FName FeatureSubTag;

	/* How much the player moves while performing this combo element. Movement is applied entirely during the InitialLockedDuration, and is in the actor's local space (ie X is always the actor's forward).*/
	UPROPERTY(Category = "Movement")
	FVector InitialMovement;

	/* Duration at the start of the animation that the movement takes place. */
	UPROPERTY(Category = "Movement")
	float MovementDuration = 0.f;
};

class UComboAnimationData : UDataAsset
{
	/* Combo elements that can chain in sequence. */
	UPROPERTY(Category = "Animations")
	TArray<FComboElement> ComboAnimations;

	/* Whether the combo can loop back to the start if interrupted from the final animation. */
	UPROPERTY(Category = "Control")
	bool bCanLoopBackToStart = false;

	/* How much control the player has over the movement while in the combo. */
	UPROPERTY(Category = "Control")
	EComboControlMode ControlMode = EComboControlMode::Locked;
}