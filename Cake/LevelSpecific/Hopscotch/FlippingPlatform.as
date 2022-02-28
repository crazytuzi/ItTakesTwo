import Cake.LevelSpecific.Hopscotch.NumberCube;

class AFlippingPlatform : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent PlatformMesh;

    UPROPERTY()
    FHazeTimeLike FlipPlatformTimeline;
    default FlipPlatformTimeline.Duration = 0.4f;

    UPROPERTY()
    EHopScotchNumber HopscotchNumber;

    UPROPERTY()
    float TimelineDuration;
    default TimelineDuration = 0.5f;

    bool bIsFlipped;
    int ActivationCounter;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        FlipPlatformTimeline.BindUpdate(this, n"FlipPlatformUpdate");
    }

    UFUNCTION()
    void FlipPlatformUpdate(float CurrentValue)
    {
        PlatformMesh.SetRelativeRotation(QuatLerp(FRotator(0,0,0), FRotator(0,180.f,0), CurrentValue));       
    }
	
	UFUNCTION(NetFunction)
	void NetFlipPlatform()
	{
		FlipPlatform();
	}
	
	UFUNCTION()
    void FlipPlatform()
    {
        if (!bIsFlipped && ActivationCounter == 0)
        {
            bIsFlipped = true;
            
            FlipPlatformTimeline.Play();
        } else 
        {
            ActivationCounter++;
        }
    }

    UFUNCTION(NetFunction)
	void NetUnFlipPlatform()
	{
		UnFlipPlatform();
	}
	
	UFUNCTION()
    void UnFlipPlatform()
    {
        if (bIsFlipped && ActivationCounter == 0)
        {
            bIsFlipped = false;

            FlipPlatformTimeline.Reverse();
        } else 
        {
            ActivationCounter--;
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
}