import Cake.Weapons.Recoil.RecoilSettings;
import Vino.Camera.Components.CameraUserComponent;

settings RecoilSettingsDefault for URecoilSettings
{

}

class URecoilComponent : UActorComponent
{
	UPROPERTY(Category = Settings)
	protected URecoilSettings RecoilSettings = RecoilSettingsDefault;

	URecoilSettings DefaultRecoilSettings;
	
	FVector2D Input;

	float RecoilDistanceMultiplier = 1.0f;

	int BulletCount = 0;

	float TimeSinceLastBulletWasFired = 0.0f;

	bool bIsFiring = false;

	private float CurrentTimeBetweenCooldown = 0.0f;
	private int BulletsFired = 0.0f;
	private bool bAllowCooldown = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		HazeOwner.ApplyDefaultSettings(RecoilSettings);
		DefaultRecoilSettings = URecoilSettings::GetSettings(HazeOwner);
	}

	void IncrementTime(float DeltaTime)
	{
		if(!bAllowCooldown)
		{
			return;
		}

		CurrentTimeBetweenCooldown = FMath::Max(CurrentTimeBetweenCooldown - 0.0f, 0.0f);
		BulletsFired = FMath::IsNearlyZero(CurrentTimeBetweenCooldown) ? 0 : BulletsFired;
	}

	void IncrementBulletsFired()
	{
		BulletsFired = FMath::Min(BulletsFired + 1, DefaultRecoilSettings.BulletsFiredMaximum);
		bAllowCooldown = true;
	}

	void ResetTimeBetweenBullets()
	{
		CurrentTimeBetweenCooldown = DefaultRecoilSettings.TimeBetweenCooldown;
	}
}
