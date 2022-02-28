import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrog;
import Cake.LevelSpecific.Garden.LevelActors.FrogPond.JumpingFrogTiltComponent;
UCLASS(Abstract, HideCategories = "Debug Collision Rendering Replication Input Actor LOD Cooking")

class ALilyPad : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UStaticMeshComponent LilyPadMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent WaterImpactEffectLocation;
	default WaterImpactEffectLocation.RelativeLocation = FVector(0.f,0.f,-50.f);

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = RootComp)
	UJumpingFrogTiltComponent FrogTiltComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.f;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LilyPadJumpOnAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LilyPadJumpOffAudioEvent;

	UPROPERTY(Category = "BounceSettings")
	float DownUnitsPerFrog = 25.f;

	UPROPERTY(Category = "BounceSettings")
	float HeightChangeSpeed = 50.f;

	UPROPERTY(Category = "Settings")
	float MaxBobHeight = 10.f;

	UPROPERTY(Category = "BounceSettings", meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0") )
	float Bouncyness = 0.65f;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UNiagaraSystem WaterImpactEffect;

	float TargetHeight;
	float BobHeightOffset = 10.f;
	float StartBobOffset = 0.f;

	float CurrentDistance;

	FHazeAcceleratedFloat AcceleratedDownVelocity;
	
	TArray<AJumpingFrog> FrogsOnLilyPad;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FActorImpactedDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"ActorLanded");
		BindOnDownImpacted(this, ImpactDelegate);

		FActorNoLongerImpactingDelegate ImpactEndedDelegate;
		ImpactEndedDelegate.BindUFunction(this, n"ActorLeft");
		BindOnDownImpactEnded(this, ImpactEndedDelegate);

		StartBobOffset = FMath::RandRange(0.f, 10.f);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		ChangePlatformHeight(DeltaTime);
	}

	UFUNCTION(NotBlueprintCallable)
	void ActorLanded(AHazeActor Actor, const FHitResult& Hit)
	{
		AJumpingFrog Frog = Cast<AJumpingFrog>(Actor);

		if(Frog != nullptr)
		{
			if (!FrogsOnLilyPad.Contains(Frog))
				FrogsOnLilyPad.AddUnique(Frog);
		}

		UHazeAkComponent::HazePostEventFireForget(LilyPadJumpOnAudioEvent, this.GetActorTransform());
		Niagara::SpawnSystemAtLocation(WaterImpactEffect, WaterImpactEffectLocation.WorldLocation);
		
		ValidateNewTargetHeight();
	}

	UFUNCTION(NotBlueprintCallable)
	void ActorLeft(AHazeActor Actor)
	{
		AJumpingFrog Frog = Cast<AJumpingFrog>(Actor);

		if(Frog != nullptr)
		{
			if (FrogsOnLilyPad.Contains(Frog))
				FrogsOnLilyPad.Remove(Frog);
		}
		
		UHazeAkComponent::HazePostEventFireForget(LilyPadJumpOffAudioEvent, this.GetActorTransform());

		ValidateNewTargetHeight();
	}

	void ChangePlatformHeight(float DeltaTime)
	{
		BobHeightOffset = FMath::Sin(System::GameTimeInSeconds + StartBobOffset) * MaxBobHeight;
		AcceleratedDownVelocity.SpringTo(TargetHeight + BobHeightOffset, HeightChangeSpeed, Bouncyness, DeltaTime);
		LilyPadMesh.SetRelativeLocation(FVector(0,0, -AcceleratedDownVelocity.Value));
	}

	void ValidateNewTargetHeight()
	{
		TargetHeight = FrogsOnLilyPad.Num() * DownUnitsPerFrog;
	}
}