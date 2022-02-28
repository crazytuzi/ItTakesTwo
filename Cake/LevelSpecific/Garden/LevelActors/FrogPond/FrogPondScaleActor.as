import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrog;

import AJumpingFrog GetJumpingFrog(AHazePlayerCharacter) from "Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrogPlayerRideComponent";
import Cake.LevelSpecific.Garden.VOBanks.GardenFrogPondVOBank;

UCLASS(Abstract)
class AFrogPondScaleActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent ScaleBaseMesh;
	default ScaleBaseMesh.SetBoundsScale(5.f);

	UPROPERTY(DefaultComponent, Attach = ScaleBaseMesh)
	USceneComponent ScaleArmRotationRoot;
	default ScaleArmRotationRoot.bUseAttachParentBound = true;

	UPROPERTY(DefaultComponent, Attach = ScaleArmRotationRoot)
	USceneComponent ScaleArmWeightRoot;
	default ScaleArmWeightRoot.bUseAttachParentBound = true;

	UPROPERTY(DefaultComponent, Attach = ScaleArmWeightRoot)
	UStaticMeshComponent ScaleArmMesh;
	default ScaleArmMesh.bUseAttachParentBound = true;
	
	UPROPERTY(DefaultComponent, Attach = ScaleArmWeightRoot)
	USceneComponent LeftWeightRotationRoot;
	default LeftWeightRotationRoot.bUseAttachParentBound = true;

	UPROPERTY(DefaultComponent, Attach = ScaleArmWeightRoot)
	USceneComponent RightWeightRotationRoot;
	default RightWeightRotationRoot.bUseAttachParentBound = true;

	UPROPERTY(DefaultComponent, Attach = LeftWeightRotationRoot)
	USceneComponent LeftWeightRoot;
	default LeftWeightRoot.bUseAttachParentBound = true;
	
	UPROPERTY(DefaultComponent, Attach = LeftWeightRoot)
	UBoxComponent LeftVOTrigger;
	default LeftVOTrigger.SetCollisionProfileName(n"TriggerOnlyPlayer");
	default LeftVOTrigger.SetBoxExtent(FVector(254.f, 254.f, 254.f));
	default LeftVOTrigger.SetRelativeScale3D(FVector(7.f, 7.f, 5.f));
	default LeftVOTrigger.SetRelativeLocation(FVector(0.f, 0.f, 1300.f));
	default LeftVOTrigger.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = RightWeightRotationRoot)
	USceneComponent RightWeightRoot;
	default RightWeightRoot.bUseAttachParentBound = true;

	UPROPERTY(DefaultComponent, Attach = RightWeightRoot)
	UBoxComponent RightVOTrigger;
	default RightVOTrigger.SetCollisionProfileName(n"TriggerOnlyPlayer");
	default RightVOTrigger.SetBoxExtent(FVector(254.f, 254.f, 254.f));
	default RightVOTrigger.SetRelativeScale3D(FVector(7.f, 7.f, 5.f));
	default RightVOTrigger.SetRelativeLocation(FVector(0.f, 0.f, 1300.f));
	default RightVOTrigger.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = LeftWeightRoot)
	USceneComponent LeftWeightNode;
	default LeftWeightNode.bUseAttachParentBound = true;

	UPROPERTY(DefaultComponent, Attach = RightWeightRoot)
	USceneComponent RightWeightNode;
	default RightWeightNode.bUseAttachParentBound = true;

	UPROPERTY(DefaultComponent, Attach = LeftWeightRoot)
	UStaticMeshComponent LeftWeightMesh;
	default LeftWeightMesh.bUseAttachParentBound = true;

	UPROPERTY(DefaultComponent, Attach = RightWeightRoot)
	UStaticMeshComponent RightWeightMesh;
	default RightWeightMesh.bUseAttachParentBound = true;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeLazyPlayerOverlapComponent AddCapabilityZone;

	UPROPERTY(DefaultComponent, Attach = ScaleBaseMesh)
	UHazeAkComponent HazeAkComp;
	
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ScaleRollAudioEvent;
	
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent JumpOnScaleAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent JumpOffScaleAudioEvent;

	UPROPERTY(Category = "Settings")
	TSubclassOf<UHazeCapability> FrogScaleCapability;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.f;
	default DisableComp.bRenderWhileDisabled = true;
	default DisableComp.bActorIsVisualOnly = true;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncRotationComponent BaseRotationAmount;
	default BaseRotationAmount.SmoothSyncMode = EHazeSmoothSyncMode::ConstantVelocity;
	default BaseRotationAmount.NumberOfSyncsPerSecond = 10;

	TArray<AJumpingFrog> FrogsOnLeftWeight;
	TArray<AJumpingFrog> FrogsOnRightWeight;

	FHazeAcceleratedRotator AccRotation;

	float OverlapWeightRadius = 1000.f;

	UPROPERTY(Category = "Settings")
	float WeightDistance = 2300.0f;

	UPROPERTY(Category = "Settings")
	float WeightRotationSpeed = 1.f;

	UPROPERTY(Category = "Settings")
	float Acceleration = 0.5f;

	UPROPERTY(Category = "Settings")
	float LandingImpulse = 1000.f;

	UPROPERTY(Category = "Settings")
	float RollPerFrog = 20.f;

	UPROPERTY(Category = "Settings")
	float RotationSpeed = 10.f;

	UPROPERTY(Category = "Setup")
	UGardenFrogPondVOBank VOBank;
	
	float DesiredRoll;

	float CurrentRoll;

	float DesiredSpeed;

	float CurrentSpeed;

	bool Reseting;

	FRotator StartingRotation;
	
	int FrogsInZone = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapabilityZone.OnPlayerBeginOverlap.AddUFunction(this, n"EnterTrigger");
		AddCapabilityZone.OnPlayerEndOverlap.AddUFunction(this, n"ExitTrigger");
		HazeAkComp.HazePostEvent(ScaleRollAudioEvent);

		LeftVOTrigger.OnComponentBeginOverlap.AddUFunction(this, n"OnVOTriggerOverlap");
		RightVOTrigger.OnComponentBeginOverlap.AddUFunction(this, n"OnVOTriggerOverlap");
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(FrogsInZone > 0
			|| ScaleBaseMesh.WasRecentlyRendered(1.f)
			|| LeftWeightMesh.WasRecentlyRendered(1.f)
			|| LeftWeightMesh.WasRecentlyRendered(1.f) )
		{
			ApplyBaseRotation(DeltaTime);
			if(ScaleArmWeightRoot.RelativeRotation.Roll != DesiredRoll)
			{
				CurrentRoll = FMath::FInterpConstantTo(CurrentRoll, DesiredRoll, DeltaTime, WeightRotationSpeed);
				ApplyWeightRotation(CurrentRoll);
			}
		
			HazeAkComp.SetRTPCValue("Rtpc_Garden_FrogPond_Platform_Scale_Roll", CurrentRoll);
		}
	}

	void ApplyBaseRotation(float DeltaTime)
	{
		if(HasControl())
		{
			float YawToAdd = RotationSpeed * DeltaTime;
       		FRotator NewRotation = FRotator(0.f, YawToAdd, 0.f);
			ScaleBaseMesh.AddLocalRotation(NewRotation);
			BaseRotationAmount.Value = ScaleBaseMesh.RelativeRotation;
		}
		else
		{
			AccRotation.AccelerateTo(BaseRotationAmount.Value, 1.f, DeltaTime);
			ScaleBaseMesh.SetRelativeRotation(AccRotation.Value);
			
			//ScaleBaseMesh.SetRelativeRotation(BaseRotationAmount.Value);
		}	
	}

	void ApplyWeightRotation(float RollToSet)
	{
		ScaleArmWeightRoot.SetRelativeRotation(FRotator(0.f, 0.f, RollToSet));
		RightWeightRotationRoot.SetRelativeRotation(FRotator(0.f,0.f, -RollToSet));
		LeftWeightRotationRoot.SetRelativeRotation(FRotator(0.f,0.f, -RollToSet));
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterTrigger(AHazePlayerCharacter Player)
	{	
		AJumpingFrog Frog = GetJumpingFrog(Player);
		if(Frog == nullptr)
			return;

		Frog.AddCapability(FrogScaleCapability);
		FrogsInZone++;
	}

	UFUNCTION(NotBlueprintCallable)
	void ExitTrigger(AHazePlayerCharacter Player)
	{
		AJumpingFrog Frog = GetJumpingFrog(Player);
		if(Frog == nullptr)
			return;
		
		Frog.RemoveCapability(FrogScaleCapability);
		FrogsInZone--;
	}

	void AddFrogsOnRightScale(AJumpingFrog Frog)
	{
		if(FrogsOnRightWeight.Contains(Frog))
			return;
		
		FrogsOnRightWeight.Add(Frog);
		CalculateTargetRotation();
		Frog.FrogHazeAkComp.HazePostEvent(JumpOnScaleAudioEvent);
	}

	void AddFrogsOnLeftScale(AJumpingFrog Frog)
	{
		if(FrogsOnLeftWeight.Contains(Frog))
			return;
		
		FrogsOnLeftWeight.Add(Frog);
		CalculateTargetRotation();
		Frog.FrogHazeAkComp.HazePostEvent(JumpOnScaleAudioEvent);
	}

	void RemoveFrogFromScale(AJumpingFrog Frog)
	{
		FrogsOnRightWeight.RemoveSwap(Frog);
		FrogsOnLeftWeight.RemoveSwap(Frog);
		CalculateTargetRotation();
		Frog.FrogHazeAkComp.HazePostEvent(JumpOffScaleAudioEvent);	
	}

	void CalculateTargetRotation()
	{
		DesiredRoll = 0.f;

		for(AJumpingFrog Frog : FrogsOnRightWeight)
		{
			DesiredRoll += RollPerFrog;
		}

		for(AJumpingFrog Frog : FrogsOnLeftWeight)
		{
			DesiredRoll -= RollPerFrog;
		}
	}

	UFUNCTION()
	void EnableVOTriggers()
	{
		RightVOTrigger.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
		LeftVOTrigger.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	}

	UFUNCTION()
	void DisableVOTriggers()
	{
		RightVOTrigger.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		LeftVOTrigger.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION()
	void OnVOTriggerOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
		UPrimitiveComponent OtherComponent, int OtherBodyIndex,
		bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		
		if(Player == nullptr)
		{
			AJumpingFrog Frog = Cast<AJumpingFrog>(OtherActor);

			if(Frog == nullptr || Frog.MountedPlayer == nullptr)
				return;
			else
			{
				Player = Frog.MountedPlayer;
			}
		}

		if(Player.IsMay())
		{
			PlayFoghornVOBankEvent(VOBank, n"FoghornDBGardenFrogPondScalePuzzleJumpFrogNY", Actor2 = GetJumpingFrog(Player));
			DisableVOTriggers();
		}
	}
}