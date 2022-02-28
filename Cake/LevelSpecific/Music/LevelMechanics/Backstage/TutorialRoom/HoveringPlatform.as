import Vino.Movement.Components.MovementComponent;
import Vino.Tilt.TiltComponent;
import Vino.Bounce.BounceComponent;
import Cake.LevelSpecific.Music.Singing.SongOfLife.SongOfLifeComponent;
import Peanuts.Audio.AudioStatics;

event void FOnHoveringStart(AHoveringPlatform Platform);
event void FOnHoveringStop(AHoveringPlatform Platform);

class AHoveringPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent BridgePieceMesh;
	UPROPERTY(DefaultComponent, Attach = BridgePieceMesh)
	UBoxComponent Trigger;
	UPROPERTY(DefaultComponent, Attach = BridgePieceMesh)
	UArrowComponent NewTargetLocation;
	UPROPERTY(DefaultComponent, Attach = BridgePieceMesh)
	UStaticMeshComponent DeathVolume;

	UPROPERTY(DefaultComponent, Attach = BridgePieceMesh)
	USongOfLifeComponent SongOfLifeComponent;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent SmoothFloatSyncVector;

	UPROPERTY(DefaultComponent, Attach = BridgePieceMesh)
	UTiltComponent TiltComp;
	UPROPERTY(DefaultComponent, Attach = BridgePieceMesh)
	UBounceComponent BounceComp;

	UPROPERTY()
	FOnHoveringStart OnHoveringStart;
	UPROPERTY()
	FOnHoveringStop OnHoveringStop;

	bool bSongOfLifeActive = false;
	bool bAllowReactivation = true;
//	bool bPowerfulSongActive = false;
	FHazeAcceleratedVector AcceleratedVector;
	FHazeAcceleratedFloat AcceleratedFloatEmissive;
	FHazeAcceleratedFloat AcceleratedFloatTemperature;
	FVector NewTargetLocationValue;
	FVector NewActorLocationValue;
	FVector ActorOriginalLoction;
	UPROPERTY()
	float PlatformSpeedUp = 10;
	UPROPERTY()
	float PlatformSpeedDown = 10;
	UPROPERTY()
	float StiffnessUp = 0.475f;
	UPROPERTY()
	float StiffnessDown = 0.85f;
	UPROPERTY()
	bool bCodyIsOnPlatform = false;
	UPROPERTY()
	bool bMayIsOnPlatform = false;
	UPROPERTY()
	float InputDelay;
	bool HasBeenActivatedOnce = false;

	float fInterpFloatYaw;
	float fInterpFloatPitch;
	float fInterpFloatRoll;
	UPROPERTY()
	float OscilationOffest = 1;

	UPROPERTY()
	bool bUseOscilation = true;
	bool bHoveringActive= false;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		//SetControlSide(Game::May);
		//SmoothFloatSyncVector.OverrideControlSide(Game::GetMay());
		SongOfLifeComponent.OnStartAffectedBySongOfLife.AddUFunction(this, n"SongOfLifeStarted");
		SongOfLifeComponent.OnStopAffectedBySongOfLife.AddUFunction(this, n"SongOfLifeEnded");
		AcceleratedVector.Value = GetActorLocation();
		NewTargetLocationValue = NewTargetLocation.GetWorldLocation();
		ActorOriginalLoction = GetActorLocation();
		AcceleratedFloatEmissive.Value = 31;
		AcceleratedFloatTemperature.Value = 900;
		UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_World_Music_Backstage_Platform_HoveringPlatform", 0);
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TickMovement(DeltaSeconds);
		//SmoothFloatSyncVector.Value = GetActorLocation();

		if(Game::GetMay().HasControl())
		{
		//	TickMovement(DeltaSeconds);
		//	SmoothFloatSyncVector.Value = GetActorLocation();
		}
		else
		{	
			//AcceleratedVector.Value = SmoothFloatSyncVector.Value;
			//SetActorLocation(FVector(SmoothFloatSyncVector.Value));
		}
	}

	UFUNCTION()
	void TickMovement(float DeltaSeconds)
	{
		if(bUseOscilation)
		{
			FRotator RelativeRotation;
			RelativeRotation.Yaw = FMath::Sin(Time::GameTimeSeconds * 3 + + OscilationOffest) * 8.f;
			RelativeRotation.Pitch = FMath::Sin(Time::GameTimeSeconds * 1.5f + OscilationOffest) * 4.f;
			RelativeRotation.Roll = FMath::Sin(Time::GameTimeSeconds * 2 + OscilationOffest) * 2.f;

			fInterpFloatYaw = FMath::FInterpTo(fInterpFloatYaw, RelativeRotation.Yaw, DeltaSeconds, 3.f);
			fInterpFloatPitch = FMath::FInterpTo(fInterpFloatPitch, RelativeRotation.Pitch, DeltaSeconds, 3.f);
			fInterpFloatRoll = FMath::FInterpTo(fInterpFloatRoll, RelativeRotation.Roll, DeltaSeconds, 3.f);
			RootComp.SetRelativeRotation(FRotator(fInterpFloatPitch,fInterpFloatYaw, fInterpFloatRoll));
		}

		if(!HasBeenActivatedOnce)
			return;

/*
		if(bPowerfulSongActive)
		{
			AcceleratedVector.SpringTo(NewTargetLocationValue - FVector(0,0, 1075), 200, 0.7, DeltaSeconds);
			NewActorLocationValue = AcceleratedVector.Value;
			SetActorLocation(AcceleratedVector.Value);

			AcceleratedFloatEmissive.SpringTo(10, 6, 0.9f, DeltaSeconds);
			AcceleratedFloatTemperature.SpringTo(500, 6, 0.9f, DeltaSeconds);
			BridgePieceMesh.SetScalarParameterValueOnMaterials(n"EmissiveStrength", AcceleratedFloatEmissive.Value);
			BridgePieceMesh.SetScalarParameterValueOnMaterials(n"Temperature", AcceleratedFloatTemperature.Value);
		} 
		
		if(bPowerfulSongActive)
			return;
*/

		if(bSongOfLifeActive)
		{			
			AcceleratedVector.SpringTo(NewTargetLocationValue, PlatformSpeedUp, StiffnessUp, DeltaSeconds);
			NewActorLocationValue = AcceleratedVector.Value;
			SetActorLocation(AcceleratedVector.Value);

			AcceleratedFloatEmissive.SpringTo(0, 2, 0.9f, DeltaSeconds);
			AcceleratedFloatTemperature.SpringTo(0, 2, 0.9f, DeltaSeconds);
			BridgePieceMesh.SetScalarParameterValueOnMaterials(n"EmissiveStrength", AcceleratedFloatEmissive.Value);
			BridgePieceMesh.SetScalarParameterValueOnMaterials(n"Temperature", AcceleratedFloatTemperature.Value);
		}
		if(!bSongOfLifeActive)
		{			
			AcceleratedVector.SpringTo(ActorOriginalLoction, PlatformSpeedDown, StiffnessDown, DeltaSeconds);
			NewActorLocationValue = AcceleratedVector.Value;
			SetActorLocation(AcceleratedVector.Value);

			AcceleratedFloatEmissive.SpringTo(31, 1, 0.9f, DeltaSeconds);
			AcceleratedFloatTemperature.SpringTo(900, 1, 0.9f, DeltaSeconds);
			BridgePieceMesh.SetScalarParameterValueOnMaterials(n"EmissiveStrength", AcceleratedFloatEmissive.Value);
			BridgePieceMesh.SetScalarParameterValueOnMaterials(n"Temperature", AcceleratedFloatTemperature.Value);
			
			if(bHoveringActive)
			{
				bHoveringActive = false;
				OnHoveringStop.Broadcast(this);
			}
		}
	}

	UFUNCTION()
	void SongOfLifeStarted(FSongOfLifeInfo Info)
	{
		System::SetTimer(this, n"DelaySongOfLifeStarted", InputDelay, false);	
	}
	UFUNCTION()
	void DelaySongOfLifeStarted()
	{
		if(!bAllowReactivation)
			return;

		HasBeenActivatedOnce = true;
		bSongOfLifeActive = true;

		if(bHoveringActive == false)
		{
			OnHoveringStart.Broadcast(this);
			bHoveringActive = true;
		}
	}

	UFUNCTION()
	void SongOfLifeEnded(FSongOfLifeInfo Info)
	{
		System::SetTimer(this, n"DelaySongOfLifeEnded", InputDelay, false);	
	}
	UFUNCTION()
	void DelaySongOfLifeEnded()
	{
		if(!bAllowReactivation)
			return;

		bSongOfLifeActive = false;
	}

/*
	UFUNCTION()
	void PowerfulSongImpact()
	{
		//This will differ in network in certain cases but its mostly a visual thing so does not matter
		if(AcceleratedVector.Value.Z > 5200)
			return;
			
		System::SetTimer(this, n"DelayPowerfulSongImpact", InputDelay, false);	
	}
	UFUNCTION()
	void DelayPowerfulSongImpact()
	{
		HasBeenActivatedOnce = true;
		bPowerfulSongActive = true;
		System::SetTimer(this, n"StopPowerfulSongImpact", 0.3f, false);	
	}
	UFUNCTION()
	void StopPowerfulSongImpact()
	{
		bPowerfulSongActive = false;
	}
*/


	UFUNCTION()
	void CompletePuzzle()
	{
		if(this.HasControl())
		{
			NetCompletePuzzle();
		}
	}
	UFUNCTION(NetFunction)
	void NetCompletePuzzle()
	{
		HasBeenActivatedOnce = true;
		bAllowReactivation = false;
//		bPowerfulSongActive = false;
		bSongOfLifeActive = true;
	}
}

