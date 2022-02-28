class UCameraAssetsComponent : UActorComponent
{
	UPROPERTY()
	UCurveFloat SpringArmLagSpeedCurve = Asset("/Game/Blueprints/Cameras/Curves/Curve_SpringArmAccelerationDurationByLagSpeed.Curve_SpringArmAccelerationDurationByLagSpeed");
}