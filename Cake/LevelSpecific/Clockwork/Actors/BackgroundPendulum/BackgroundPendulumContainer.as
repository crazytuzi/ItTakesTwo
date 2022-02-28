import Cake.LevelSpecific.Clockwork.Actors.BackgroundPendulum.BackgroundPendulum;
import Vino.Audio.AudioActors.HazeAmbientSound;

struct FPendulumCollectData
{
	UPROPERTY()
	UStaticMesh MeshToUse;

	UPROPERTY()
	FTransform WorldTransform;

	UPROPERTY()
	FTransform RootTransform;

	UPROPERTY()
	FTransform MeshTransform;

	UPROPERTY()
	FString NameToUse;

	UPROPERTY()
	float DelayUntilStart;

	UPROPERTY()
	float RotationAmount;

	UPROPERTY()
	float SecondsForFullSwing;

	UPROPERTY()
	UAkAudioEvent PlayFromStartAudio;

	UPROPERTY()
	UAkAudioEvent ReverseFromEndAudio;
}

// Required since all the pendulum logic is made in BP
UCLASS(Abstract)
class APendulumConvertableActor : AHazeActor
{
	UFUNCTION(BlueprintEvent)
	FPendulumCollectData GeneratePendulumData()
	{
		return FPendulumCollectData();
	}
}

class ABackgroundPendulumContainer : AHazeActor
{	
	default SetActorTickInterval(0);

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.bVisualizeComponent = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PendulumRoot;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 5000;
	default DisableComponent.bActorIsVisualOnly = true;
	default DisableComponent.bRenderWhileDisabled = true;

	UPROPERTY(EditAnywhere, Category = "Pendulum")
	UCurveFloat MovementCurve = Asset("/Game/Blueprints/LevelSpecific/Clockwork/Misc/BackgroundPendulumCurve.BackgroundPendulumCurve");

	// The time after the first rendering that we will continue to update the pendulum
	UPROPERTY(EditAnywhere, Category = "Pendulum|Optimization")
	float UpdateLingerTime = 5.f;

	UPROPERTY(EditAnywhere, Category = "Pendulum|Optimization")
	bool bUseForcedUpdateInterval = true;

	// If true, the pendulums movement will always be updated if we are inside the visual range
	UPROPERTY(EditInstanceOnly, Category = "Pendulum|Optimization")
	bool bAlwaysUpdateIfInsideRange = false;

	// A value that makes the pendulum update even if it has not been rendered since some pendulums swing into vision
	UPROPERTY(EditAnywhere, Category = "Pendulum|Optimization", meta = (EditCondition = "bUseForcedUpdateInterval"))
	FHazeMinMax RandomForcedUpdateInterval = FHazeMinMax(0.5f, 1.f);

	UPROPERTY(EditInstanceOnly, Category = "Pendulum")
	TArray<APendulumActor> Pendulums;

	UPROPERTY(EditInstanceOnly, Category = "EDITOR ONLY")
	float ConversionDistance = -1;

	UPROPERTY(EditConst)
	FTransform LockedPendulumRootTransform;
	default LockedPendulumRootTransform.SetScale3D(FVector::ZeroVector);

	float TimeRangeMin = 0.f, TimeRangeMax = 1.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(LockedPendulumRootTransform.GetScale3D().IsNearlyZero())
			LockedPendulumRootTransform = PendulumRoot.GetWorldTransform();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		for(auto Pendulum : Pendulums)
			Pendulum.Mesh.SetVisibility(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorPostDisabled()
	{
		for(auto Pendulum : Pendulums)
			Pendulum.Mesh.SetVisibility(false);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		MovementCurve.GetTimeRange(TimeRangeMin,TimeRangeMax);
		const float GameTime = Time::GetGameTimeSeconds();
		for(auto Pendulum : Pendulums)
		{
			Pendulum.LastUpdateTime = GameTime + TimeRangeMin;
			Pendulum.MovementTime =	FMath::Max(TimeRangeMax - Pendulum.DelayUntilStart, 0.f);
			Pendulum.ForcedUpdateToGameTime = GameTime + 0.5f;
			UpdatePendulum(Pendulum, 0.f);
		}	
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const float GameTime = Time::GetGameTimeSeconds();
		for(auto Pendulum : Pendulums)
		{
			UpdatePendulum(Pendulum, GameTime);
		}
	}

	void UpdatePendulum(APendulumActor Pendulum, float GameTime)
	{
		const bool bHasBeenRendered = Pendulum.Mesh.WasRecentlyRendered(UpdateLingerTime);
		if(bHasBeenRendered)
		{
			Pendulum.ForcedUpdateToGameTime = GameTime + UpdateLingerTime;
		}
		else if(bAlwaysUpdateIfInsideRange && Pendulum.Mesh.IsVisible())
		{
			Pendulum.ForcedUpdateToGameTime = GameTime + UpdateLingerTime;
		}

		if(GameTime < Pendulum.ForcedUpdateToGameTime 
			|| (bUseForcedUpdateInterval && GameTime >= Pendulum.LastUpdateTime + Pendulum.RandomTimeUpdate))
		{
			float DeltaTime = GameTime - Pendulum.LastUpdateTime;	
			Pendulum.LastUpdateTime = GameTime;

			// We use a random timer to sometimes force update the pendulums since some of them can swing into picture
			Pendulum.RandomTimeUpdate = FMath::RandRange(RandomForcedUpdateInterval.Min, RandomForcedUpdateInterval.Max);

			float TimeLeftToMove = DeltaTime * Pendulum.PlayRate;
			UAkAudioEvent AudioEventToPlay = nullptr;

			while(TimeLeftToMove > KINDA_SMALL_NUMBER)
			{
				const float LastMoveTime = Pendulum.MovementTime;
				
				// Forward Movement
				if(Pendulum.bMovingForward)
				{
					Pendulum.MovementTime += TimeLeftToMove;
					if(Pendulum.MovementTime >= TimeRangeMax)
					{
						Pendulum.MovementTime = TimeRangeMax;
						AudioEventToPlay = Pendulum.ReverseFromEndAudio;
						Pendulum.bMovingForward = false;
					}

					TimeLeftToMove -= Pendulum.MovementTime - LastMoveTime;	
				}
				else
				{
					Pendulum.MovementTime -= TimeLeftToMove;
					if(Pendulum.MovementTime <= TimeRangeMin)
					{
						Pendulum.MovementTime = TimeRangeMin;
						AudioEventToPlay = Pendulum.PlayFromStartAudio;
						Pendulum.bMovingForward = true;
					}

					TimeLeftToMove -= LastMoveTime - Pendulum.MovementTime;	
				}
			}

			const float CurveValue = MovementCurve.GetFloatValue(Pendulum.MovementTime) * 2.f;
			FQuat NewRotation = FQuat::Slerp(FRotator(0.f, 0.f, Pendulum.RotationAmount).Quaternion(), FRotator(0.f, 0.f, -Pendulum.RotationAmount).Quaternion(), CurveValue);
			Pendulum.RotationRoot.SetRelativeRotation(NewRotation);

			Pendulum.PlaySound(AudioEventToPlay);
		}
	}

	#if EDITOR

	// This will fill all the pendulum data from BP
	UFUNCTION(CallInEditor, Category = "EDITOR ONLY")
	void CovertBPtoAS()
	{
		TArray<APendulumConvertableActor> OldPendulums;
		GetAllActorsOfClass(APendulumConvertableActor::StaticClass(), OldPendulums);
		for(auto Pendulum : OldPendulums)
		{
			if(ConversionDistance > 0 && Pendulum.GetDistanceTo(this) > ConversionDistance)
				continue;

			const FPendulumCollectData Data = Pendulum.GeneratePendulumData();

			FString SpawnName = GetName();
			SpawnName += "_Pendulum_" + Pendulums.Num();
			
			auto NewPendulum = Cast<APendulumActor>(SpawnActor(APendulumActor::StaticClass(), FVector::ZeroVector, FRotator::ZeroRotator, FName(SpawnName), true, GetLevel()));
			NewPendulum.DelayUntilStart = Data.DelayUntilStart;
			NewPendulum.RotationAmount = Data.RotationAmount;
			NewPendulum.SecondsForFullSwing = Data.SecondsForFullSwing;
			FinishSpawningActor(NewPendulum);

			NewPendulum.RootComponent.SetWorldTransform(Data.WorldTransform);
			NewPendulum.RotationRoot.SetRelativeTransform(Data.RootTransform);
			NewPendulum.Mesh.SetStaticMesh(Data.MeshToUse);
			NewPendulum.Mesh.SetRelativeTransform(Data.MeshTransform);
	
			NewPendulum.PlayFromStartAudio = Data.PlayFromStartAudio;
			NewPendulum.ReverseFromEndAudio = Data.ReverseFromEndAudio;
			
			NewPendulum.AttachRootComponentTo(PendulumRoot, NAME_None, EAttachLocation::KeepWorldPosition);
			Pendulums.Add(NewPendulum);
			Pendulum.DestroyActor();
		}
	}

	// This will move the actor to the center of the cogs and update the disable range to cover the actor
	UFUNCTION(CallInEditor, Category = "EDITOR ONLY")
	void UpdateDisableComponentRangeAndRootPosition()
	{
		if(Pendulums.Num() == 0)
			return;

		float BiggestDistance = 0;
		FVector MiddleOrigin = FVector::ZeroVector; 
		for(auto Pendulum : Pendulums)
		{
			FVector Origin = FVector::ZeroVector;
			FVector Extends = FVector::ZeroVector;
			Pendulum.GetActorBounds(false, Origin, Extends);
			MiddleOrigin += Origin;
			float Distance = (Origin + Extends).Distance(PendulumRoot.GetWorldLocation());
			if(Distance > BiggestDistance)
				BiggestDistance = Distance;
		}
		
		MiddleOrigin /= Pendulums.Num();
		const FVector OldRootLocation = PendulumRoot.GetWorldLocation();
		SetActorLocation(MiddleOrigin);
		PendulumRoot.SetWorldLocation(OldRootLocation);

		DisableComponent.AutoDisableRange = BiggestDistance;
		DisableComponent.AutoDisableRange *= FMath::Sqrt(3.f);
		DisableComponent.AutoDisableRange *= 1.5f;
		DisableComponent.AutoDisableRange = FMath::CeilToInt(DisableComponent.AutoDisableRange);
	}

	UFUNCTION(CallInEditor, Category = "EDITOR ONLY")
	void LockedRootTransform_Update()
	{
		LockedPendulumRootTransform = PendulumRoot.GetWorldTransform();
	}

	UFUNCTION(CallInEditor, Category = "EDITOR ONLY")
	void LockedRootTransform_Apply()
	{
		PendulumRoot.SetWorldTransform(LockedPendulumRootTransform);
	}

	#endif
};