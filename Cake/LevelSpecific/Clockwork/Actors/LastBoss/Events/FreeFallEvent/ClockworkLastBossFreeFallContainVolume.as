import Effects.PostProcess.PostProcessing;
import Vino.Camera.Components.CameraKeepInViewComponent;
import Vino.Camera.Components.CameraUserComponent;

class AClockworkLastBossFreeFallContainVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent LeftCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent RightCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent UpCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DownCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent LeftCollisionMesh;
	default LeftCollisionMesh.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent RightCollisionMesh;
	default RightCollisionMesh.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent UpCollisionMesh;
	default UpCollisionMesh.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent DownCollisionMesh;
	default DownCollisionMesh.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CameraRoot;

	UPROPERTY(DefaultComponent, Attach = CameraRoot)
	UCameraKeepInViewComponent KeepInViewComp;
	default KeepInViewComp.PlayerFocus = EKeepinViewPlayerFocus::AllPlayers;
	default KeepInViewComp.MatchInitialVelocityFactor = 1.f;
	
	UPROPERTY(DefaultComponent, Attach = KeepInViewComp)
	UHazeCameraComponent Camera;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent PlayerFacingDirection;

	UPROPERTY(DefaultComponent, Attach = Root)
	USpotLightComponent Spotlight;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent FloorMesh;
	default FloorMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
	default FloorMesh.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	USkeletalMeshComponent CodyLocation;
	default CodyLocation.bHiddenInGame = true;
	default CodyLocation.bIsEditorOnly = true;
	default CodyLocation.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	USkeletalMeshComponent MayLocation;
	default MayLocation.bHiddenInGame = true;
	default MayLocation.bIsEditorOnly = true;
	default MayLocation.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CogTopLeft;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CogBotRight;

	UPostProcessingComponent PostProcessingComp;

	FVector CamStartLoc;
	FRotator CamStartRot;
	FVector CamRootStartLoc;

	float CamDistance = 1500.f;
	
	float CamOffsetY = 150.f;
	float CamOffsetX = 150.f;

	float CamOffsetYaw = 7.5f;
	float CamOffsetPitch = 7.5f;

	float XCamAlpha;
	float YCamAlpha;

	bool bEnableDynamicCamera = false;
	
	UPROPERTY()
	FHazeCameraClampSettings CamClampSettings;

	bool bActive = false;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PostProcessingComp = UPostProcessingComponent::Get(Game::GetCody());
		Game::GetCody().ApplyFieldOfView(65.f, FHazeCameraBlendSettings(), this);

		CamStartLoc = Camera.RelativeLocation;
		CamRootStartLoc = CameraRoot.RelativeLocation;
		CamStartRot = Camera.RelativeRotation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bActive)
			return;

		// if (Game::GetCody().IsPlayerDead() || Game::GetMay().IsPlayerDead())
		// {
		// 	CamDistance = 1000.f;
		// } else 
		// {
		// 	float DistanceBetweenPlayers = (Game::GetCody().GetActorLocation() - Game::GetMay().GetActorLocation()).Size();
		// 	CamDistance = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 1000.f), FVector2D(1000.f, 1500.f), DistanceBetweenPlayers);

		// 	FVector MiddleLoc = (Game::GetCody().GetActorLocation() + Game::GetMay().GetActorLocation()) / 2.f;
		// 	FVector DirToMiddle = MiddleLoc - Camera.GetWorldLocation();
			
		// 	FRotator NewRot = DirToMiddle.ToOrientationRotator();
		// 	NewRot.Roll = 0.f;
		// 	Camera.SetWorldRotation(NewRot);
		// 	Print("NewRot: " + NewRot);
		// }
	}

	UFUNCTION()
	void SetFreeFallContainerActive(bool bNewActive)
	{
		bActive = bNewActive;
		bEnableDynamicCamera = bNewActive;
		SetShimmerActive(bNewActive);
	}

	UFUNCTION()
	void SetShimmerActive(bool bActive)
	{
		PostProcessingComp.SpeedShimmer = bActive ? 1.f : 0.f;
	}	

	UFUNCTION()
	void UnHideFloor()
	{
		FloorMesh.SetHiddenInGame(false);
		FloorMesh.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	}

	void SetCurrentHeight(float ZHeight)
	{
		ActorLocation = FVector(ActorLocation.X, ActorLocation.Y, ZHeight);

		// FVector CamWorldLoc;
		// CamWorldLoc = CameraRoot.WorldLocation;
		// CamWorldLoc.Z = ZHeight + CamDistance;

		//CameraRoot.WorldLocation = CamWorldLoc;
	}

	/*UFUNCTION()
	void MoveCameraToSecondLocation()
	{
		Camera.SetRelativeLocation(CamStartLoc);
		CameraRoot.SetRelativeLocation(CamRootStartLoc + FVector(0.f, 0.f, 1000.f));
		Camera.SetRelativeRotation(CamStartRot);
	}*/
}