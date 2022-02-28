import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackComponent;
import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrog;

class AFrogPondFountainPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UActorImpactedCallbackComponent ImpactComp;

	UPROPERTY()
	FHazeConstrainedPhysicsValue PhysicsBounce;
	default PhysicsBounce.Friction = 2.f;
	default PhysicsBounce.bHasLowerBound = false;
	default PhysicsBounce.bHasUpperBound = false;

	int AmountOfFrogsOnPlatform;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactComp.OnActorDownImpacted.AddUFunction(this, n"OnDownImpacted");
		ImpactComp.OnDownImpactEnding.AddUFunction(this, n"OnDownImpactEnding");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		PhysicsBounce.Friction = 5.f;
		PhysicsBounce.SpringTowards(AmountOfFrogsOnPlatform * -50.f, 50.f);
		PhysicsBounce.Update(DeltaTime);
		
		float BobAmount = FMath::Sin(Time::GameTimeSeconds * 20.f);
	}

	UFUNCTION()
	void OnDownImpacted(AHazeActor Actor, const FHitResult& Hit)
	{
		AJumpingFrog Frog = Cast<AJumpingFrog>(Actor);
		if (Frog == nullptr)
			return;

		AmountOfFrogsOnPlatform++;
		PhysicsBounce.AddImpulse(-400.f);
	}

	UFUNCTION()
	void OnDownImpactEnding(AHazeActor Actor)
	{
		AJumpingFrog Frog = Cast<AJumpingFrog>(Actor);
		if (Frog == nullptr)
			return;
		AmountOfFrogsOnPlatform--;		
	}

	UFUNCTION(BlueprintPure)
	float GetPhysicsBounceValue()
	{
		return PhysicsBounce.Value + (FMath::Sin(Time::GameTimeSeconds * 25.f) * 1.5f);
	}
}