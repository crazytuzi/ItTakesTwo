import Vino.Movement.MovementSettings;
import Vino.Pickups.PickupType;
import Vino.Pickups.Throw.PickupAimCrosshairWidget;

class UPickupDataAsset : UDataAsset
{
	UPROPERTY()
	EPickupType PickupType = EPickupType::Big;

	UPROPERTY()
	UHazeCapabilitySheet PickupCapabilitySheet;


	UPROPERTY(Category = "Movement")
	UMovementSettings MovementSettings;


	UPROPERTY(Category = "Animation")
	UAnimSequence PickupAnimation;

	UPROPERTY(Category = "Animation")
	UAnimSequence PutDownAnimation;

	UPROPERTY(Category = "Animation")
	UAnimSequence PutDownInPlaceAnimation;

	UPROPERTY(Category = "Animation")
	UAnimSequence ThrowAnimation;

	UPROPERTY(Category = "Animation")
	UHazeLocomotionAssetBase CarryLocomotion;

	UPROPERTY(Category = "Animation")
	UHazeLocomotionAssetBase AimStrafeLocomotion;


	UPROPERTY(Category = "Aiming")
	UAimOffsetBlendSpace AimSpace;

	UPROPERTY(Category = "Aiming")
	TSubclassOf<UPickupAimCrosshairWidget> AimCrosshairWidgetClass;

	UPROPERTY(Category = "Aiming")
	UCurveFloat AimChargeCurve;


	UPROPERTY(Category = "Throwing")
	UForceFeedbackEffect ThrowForceFeedback;
}