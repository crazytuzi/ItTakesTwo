import Vino.Trajectory.TrajectoryComponent;
import Vino.Movement.Helpers.BurstForceStatics;

event void FHomeworkDeskLidSignature();

UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class AHomeworkDeskLid : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UStaticMeshComponent InivisibleMesh;
	default InivisibleMesh.bHiddenInGame = true;
	default InivisibleMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UBoxComponent OpenLidCollision;
	default OpenLidCollision.RelativeLocation = FVector(-570.f, -10.f, 250.f);
	default OpenLidCollision.BoxExtent = FVector(400.f, 700.f, 250.f);

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent CodyJumpToTarget;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent MayJumpToTarget;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UBoxComponent BoxCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent OtherDeskCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent ReadyToLaunchCollision;

	UPROPERTY()
	FHomeworkDeskLidSignature HasLaunchedPlayersEvent();

	UPROPERTY()
	AHomeworkDeskLid OtherHomeworkDeskLid;

	UPROPERTY()
	bool bShouldUnblockMovement;

	UPROPERTY()
	bool bShouldLaunchPlayerOnOverlap;

	UPROPERTY()
	bool bStartLaunchPlayerOverlapDisabled;

	UPROPERTY()
	bool bOverrideLaunch;
	
	UPROPERTY()
	FHazeTimeLike OpenLidTimeline;
	default OpenLidTimeline.Duration = 5.f;

	UPROPERTY()
	float JumpToAdditionalHeight = 2000.f;

	UPROPERTY()
	TArray<AHazeActor> ActorToAttachDuringFlip;

	FRotator InitialRotation;
	FRotator TargetRotation;

	bool bLandedOnOtherDesk;
	bool bHasLaunchedPlayers;

	float ReadyToLaunchCheckTimer = 0.5f;
	bool bShouldTickReadyToLaunchTimer = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OpenLidTimeline.BindUpdate(this, n"OpenLidTimelineUpdate");

		OtherDeskCollision.OnComponentBeginOverlap.AddUFunction(this, n"OtherDeskBeginOverlap");
		OpenLidCollision.OnComponentEndOverlap.AddUFunction(this, n"OpenLidCollisionEndOverlap");

		InitialRotation = Mesh.RelativeRotation;
		TargetRotation = FRotator(Mesh.RelativeRotation + FRotator(-30.f, 0.f, 0.f));

		if (bStartLaunchPlayerOverlapDisabled)
			OpenLidCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!HasControl())
			return;

		if (bShouldTickReadyToLaunchTimer && !bHasLaunchedPlayers)
		{
			ReadyToLaunchCheckTimer -= DeltaTime;
			if (ReadyToLaunchCheckTimer <= 0.f)
			{
				bShouldTickReadyToLaunchTimer = false;
				CheckIfLidCanBeOpened();
			}
		}
	}

	UFUNCTION()
	void CheckIfLidCanBeOpened()
	{
		// Open and lid and launch player here!
		TArray<AActor> Actors;
		ReadyToLaunchCollision.GetOverlappingActors(Actors);

		bool bCodyInVolume = false;
		bool bMayInVolume = false;

		for(auto Actor : Actors)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
			if (Player == nullptr)
				continue;
			
			if (Player == Game::GetMay())
				bMayInVolume = true;

			if (Player == Game::GetCody())
				bCodyInVolume = true;
		}

		if (bCodyInVolume && bMayInVolume)
			NetOpenLid();
		else
			StartCheckLaunchTimer();
	}

	UFUNCTION(NetFunction)
	void NetOpenLid()
	{
		AttachActorBeforeFlip();

		AudioDeskLidOpen();

		if (!bOverrideLaunch)
			LaunchPlayers();
		else
			StartCheckLaunchTimer();
		
		
		Mesh.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);
		//Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		OpenLidTimeline.Play();
		HasLaunchedPlayersEvent.Broadcast();
	}

	void StartCheckLaunchTimer()
	{
		ReadyToLaunchCheckTimer = 0.5f;
		bShouldTickReadyToLaunchTimer = true;
	}

	UFUNCTION()
	void OpenLidTimelineUpdate(float CurrentValue)
	{
		Mesh.SetRelativeRotation(QuatLerp(InitialRotation, TargetRotation, CurrentValue));
	}

	void LaunchPlayers()
	{
		TArray<AActor> ActorArray;
		BoxCollision.GetOverlappingActors(ActorArray);

		SetInvisibleCollisionEnabled(false);
		for (auto Player : Game::GetPlayers())
		{
			if (!Player.HasControl())
				continue;

			FHazeJumpToData JumpData;
			if (Player == Game::GetCody())
				JumpData.Transform = CodyJumpToTarget.WorldTransform;
			else
				JumpData.Transform = MayJumpToTarget.WorldTransform;
					
			JumpData.AdditionalHeight = JumpToAdditionalHeight; 
			JumpTo::ActivateJumpTo(Player, JumpData);
		} 
	}

	UFUNCTION()
	void SetInvisibleCollisionEnabled(bool bEnabled)
	{
		// ECollisionEnabled NewCollision = bEnabled ? ECollisionEnabled::QueryAndPhysics : ECollisionEnabled::NoCollision;
		// InivisibleMesh.CollisionEnabled = NewCollision;
	}

	void SetOtherInvisibleCollisionEnabled(bool bEnabled)
	{
		// ECollisionEnabled NewCollision = bEnabled ? ECollisionEnabled::QueryAndPhysics : ECollisionEnabled::NoCollision;
		// OtherHomeworkDeskLid.InivisibleMesh.CollisionEnabled = NewCollision;
	}

	UFUNCTION()
	void SetOpenLidCollisionEnabled(bool bEnabled)
	{
		ECollisionEnabled Collision = bEnabled ? ECollisionEnabled::QueryAndPhysics : ECollisionEnabled::NoCollision;
		OpenLidCollision.SetCollisionEnabled(Collision);
	}

	UFUNCTION()
    void OtherDeskBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
    {	
		if(Cast<AHazePlayerCharacter>(OtherActor) != nullptr && !bLandedOnOtherDesk)
		{
			if (bShouldUnblockMovement)
			{
				bLandedOnOtherDesk = true;
			}
			
			if (OtherHomeworkDeskLid != nullptr)
				SetOtherInvisibleCollisionEnabled(true);
		}
    }

	UFUNCTION()
    void OpenLidCollisionEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {	
		if (bShouldLaunchPlayerOnOverlap)
		{
			if (Cast<AHazePlayerCharacter>(OtherActor) != nullptr && !bHasLaunchedPlayers)
			{
				bHasLaunchedPlayers = true;
				CheckIfLidCanBeOpened();
			}
		}
    }

	void AttachActorBeforeFlip()
	{
		for (AHazeActor Actor :ActorToAttachDuringFlip)
		{
			Actor.AttachToComponent(Mesh, n"", EAttachmentRule::KeepWorld);
		}
	}

	FRotator QuatLerp(FRotator A, FRotator B, float Alpha)
    {
		FQuat AQuat(A);
		FQuat BQuat(B);
		FQuat Result = FQuat::Slerp(AQuat, BQuat, Alpha);
		Result.Normalize();
		return Result.Rotator();
    }

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioDeskLidOpen()
	{

	}
}