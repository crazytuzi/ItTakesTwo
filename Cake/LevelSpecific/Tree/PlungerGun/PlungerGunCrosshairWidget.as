import Cake.LevelSpecific.Tree.PlungerGun.PlungerGunSettings;
import Vino.Trajectory.TrajectoryStatics;

class UPlungerGunCrosshairWidget : UHazeUserWidget
{
	FTransform FireOrigin;

	UPROPERTY(BlueprintReadOnly)
	float ChargePercent = 0.f;

	UFUNCTION(BlueprintPure)
	FVector2D GetCrosshairTargetScreenSpace()
	{
		FVector OriginLoc = FireOrigin.Location;
		FVector FireForward = FireOrigin.Rotation.ForwardVector;

		FVector TargetLoc = OriginLoc + FireForward * 800.f;

		// Next, project that onto the screen
		FVector2D ScreenPosition;
		bool bSuccess = SceneView::ProjectWorldToViewpointRelativePosition(Player, TargetLoc, ScreenPosition);
		if (!bSuccess)
			ScreenPosition = FVector2D(0.5f, 0.5f);

		return ScreenPosition;
	}

	UFUNCTION(BlueprintEvent)
	void OnPlungerGunStartCharging() {}

	UFUNCTION(BlueprintEvent)
	void OnPlungerGunFire() {}
}