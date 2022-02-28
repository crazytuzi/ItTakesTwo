import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrog;
import Cake.LevelSpecific.Garden.LevelActors.FrogPond.JumpingFrogTiltComponent;

// This actor is updated through AFroggerStreamActor
UCLASS(Abstract)
class AFroggerPlatformActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
    UStaticMeshComponent Mesh;

	// This is handled by the manager
	UPROPERTY(DefaultComponent, NotEditable)
    UHazeDisableComponent DisableComponent;
	default DisableComponent.bActorIsVisualOnly = true;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent WaterImpactEffectLocation;
	default WaterImpactEffectLocation.RelativeLocation = FVector(0.f, 0.f, -50.f);

	UPROPERTY(DefaultComponent, Attach = WaterImpactEffectLocation)
	UNiagaraComponent WaterSplashEffectComp;

	UPROPERTY(DefaultComponent)
	UHazeSplineFollowComponent SplineMovement;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UJumpingFrogTiltComponent TiltComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LilyPadJumpOnAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LilyPadJumpOffAudioEvent;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UNiagaraSystem WaterImpactEffect;

	UPROPERTY(Category = "BounceSettings")
	float DownUnitsPerFrog = 25.f;

	UPROPERTY(Category = "BounceSettings")
	float HeightChangeSpeed = 50.f;

	UPROPERTY(Category = "BounceSettings", meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0") )
	float Bouncyness = 0.65f;

	float TargetHeight;
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
	}

	UFUNCTION(NotBlueprintCallable)
	void ActorLanded(AHazeActor Actor, const FHitResult& Hit)
	{
		AJumpingFrog Frog = Cast<AJumpingFrog>(Actor);

		if(Frog != nullptr && FrogsOnLilyPad.AddUnique(Frog))
		{
			UHazeAkComponent::HazePostEventFireForget(LilyPadJumpOnAudioEvent, GetActorTransform());
			//Niagara::SpawnSystemAtLocation(WaterImpactEffect, WaterImpactEffectLocation.WorldLocation);
			
			WaterSplashEffectComp.Activate(false);
			
			ValidateNewTargetHeight();
		}	
	}

	UFUNCTION(NotBlueprintCallable)
	void ActorLeft(AHazeActor Actor)
	{
		AJumpingFrog Frog = Cast<AJumpingFrog>(Actor);

		if(Frog != nullptr && FrogsOnLilyPad.RemoveSwap(Frog))
		{
			UHazeAkComponent::HazePostEventFireForget(LilyPadJumpOffAudioEvent, GetActorTransform());
			ValidateNewTargetHeight();
		}	
	}

	void ValidateNewTargetHeight()
	{
		TargetHeight = FrogsOnLilyPad.Num() * DownUnitsPerFrog;
	}
}
