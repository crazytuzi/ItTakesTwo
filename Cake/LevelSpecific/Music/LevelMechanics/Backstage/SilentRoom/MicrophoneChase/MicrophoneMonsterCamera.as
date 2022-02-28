import Peanuts.Spline.SplineComponent;
import Peanuts.Spline.SplineActor;
import Vino.PlayerHealth.PlayerHealthStatics;

class AMicrophoneMonsterCamera : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CameraRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PreviewTarget;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraComponent Camera;

	UPROPERTY()
	ASplineActor ConnectedSplineActor;

	UPROPERTY()
	UCurveFloat Curve;

	float CamOffset = 0.f;

	UPROPERTY()
	bool bDebugMode = false;


	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	
	}	

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{		
		FVector CodyPos = Game::GetCody().GetActorLocation();
		FVector MayPos = Game::GetMay().GetActorLocation();
		FVector MiddlePos = (CodyPos + MayPos) / 2;

		if (IsPlayerDead(Game::GetCody()))
			MiddlePos = MayPos;
		
		if (IsPlayerDead(Game::GetMay()))
			MiddlePos = CodyPos;

		FHazeSplineSystemPosition Pos = ConnectedSplineActor.Spline.GetPositionClosestToWorldLocation(bDebugMode ? CodyPos : MiddlePos, true);	
		FVector CamRot = Pos.WorldLocation - Camera.GetWorldLocation();
		CamRot.Normalize();
		Camera.SetWorldRotation(FMath::RInterpTo(Camera.WorldRotation, CamRot.ToOrientationRotator(), DeltaTime, 4.f));
		FVector NewCamPosition = Pos.WorldLocation;
		NewCamPosition += Pos.WorldForwardVector * -700.f; 
		NewCamPosition += Pos.WorldUpVector * 1000.f;
		Camera.SetWorldLocation(FMath::VInterpTo(Camera.WorldLocation, NewCamPosition, DeltaTime, 4.f));
	}
}