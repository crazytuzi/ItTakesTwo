import Cake.LevelSpecific.Clockwork.Actors.LowerClocktower.ClockworkRotatingCogTimeDilate;
import Cake.LevelSpecific.Hopscotch.HopscotchButton;
import Peanuts.Triggers.PlayerTrigger;
import Vino.Camera.Actors.SplineCamera;

class AClockworkCylinderElevatorManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;
	
	UPROPERTY()
	AClockworkRotatingCogTimeDilate RotatingPlatform;

	UPROPERTY()
	ASplineCamera SplineCam;

	UPROPERTY()
	APlayerTrigger StartSplineCamTrigger;

	UPROPERTY()
	APlayerTrigger StopSplineCamTrigger;
	
	UPROPERTY()
	AHopscotchButton Button01;
	
	UPROPERTY()
	AHopscotchButton Button02;

	bool bShouldMovePlatform = false;
	float MovePlatformAlpha;

	float MovePlatformDuration = 4.f;

	FVector StartLocation;
	FVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartSplineCamTrigger.OnPlayerEnter.AddUFunction(this, n"SplineCamTriggerOverlapped");
		StopSplineCamTrigger.OnPlayerEnter.AddUFunction(this, n"StopSplineCamTriggerOverlapped");
		
		Button01.ButtonPressedEvent.AddUFunction(this, n"Button01Pressed");
		Button02.ButtonPressedEvent.AddUFunction(this, n"Button02Pressed");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bShouldMovePlatform)
			return;

		if (MovePlatformAlpha >= 1.f)
		{
			MovePlatformAlpha = 1.f;
			bShouldMovePlatform = false;
		}
		
		RotatingPlatform.SetActorLocation(FMath::VLerp(StartLocation, TargetLocation, FVector(MovePlatformAlpha, MovePlatformAlpha, MovePlatformAlpha)));

		MovePlatformAlpha += DeltaTime / MovePlatformDuration;
	}

	UFUNCTION()
	void SplineCamTriggerOverlapped(AHazePlayerCharacter PlayerOverlapped)
	{
		FHazeCameraBlendSettings Blend;
		SplineCam.ActivateCamera(PlayerOverlapped, Blend, this);
	}

	UFUNCTION()
	void StopSplineCamTriggerOverlapped(AHazePlayerCharacter PlayerOverlapped)
	{
		SplineCam.DeactivateCamera(PlayerOverlapped);
	}

	UFUNCTION()
	void Button01Pressed(AHopscotchButton Button)
	{
		MovePlatformUp(2000.f);
	}

	UFUNCTION()
	void Button02Pressed(AHopscotchButton Button)
	{
		MovePlatformUp(3000.f);
	}

	void MovePlatformUp(float MoveAmount)
	{
		StartLocation = RotatingPlatform.GetActorLocation();
		TargetLocation = FVector(StartLocation + FVector(0.f, 0.f, MoveAmount));
		MovePlatformAlpha = 0.f;
		MovePlatformDuration = MoveAmount / 650.f;
		bShouldMovePlatform = true;
	}
}