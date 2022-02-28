import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetGenericComponent;

event void FCounterWeightStateChangedEventSignature(ECounterWeightState State);

enum ECounterWeightState
{
	IsAtStart,
	IsAtEnd,
	IsInBetween
};

class ACounterWeightActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSplineComponent Spline;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USceneComponent Anchor;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UMagnetGenericComponent Magnet;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent DistanceSync;

	UPROPERTY()
	EHazePlayer OwningPlayer;

	UPROPERTY(Category = "Counter Weight")
	FCounterWeightStateChangedEventSignature StateChanged;

	UPROPERTY()
	float Progress;

	UPROPERTY()
	float CounterWeightVelocity;

	UPROPERTY()
	float Friction = 0.9f;

	UPROPERTY()
	float PlayerInfluencingForce = 1200;

	UPROPERTY()
	float DesiredProgressPosition = -1;

	UPROPERTY()
	float ConstantForce;

	UPROPERTY()
	bool bIsAtEnd = false;

	UPROPERTY()
	bool bIsAtStart = false;

	bool bIsAtEndLastFrame = false;
	bool bIsAtStartLastFrame = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (OwningPlayer == EHazePlayer::Cody)
		{
			SetControlSide(Game::GetCody());
		}

		else
		{
			SetControlSide(Game::GetMay());
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CheckEndState();
		CheckStartState();
	}

	void CheckStartState()
	{
		if (Progress < 0.002f)
		{
			bIsAtEnd = true;
		}

		else
		{
			bIsAtEnd = false;
		}

		if (bIsAtEnd != bIsAtStartLastFrame)
		{
			if (Progress < 0.002f)
			{
				if(HasAuthority())
				{
					NetBroadCastEvent(ECounterWeightState::IsAtStart);
				}
			}

			else
			{
				if(HasAuthority())
				{
					NetBroadCastEvent(ECounterWeightState::IsInBetween);
				}
			}

			bIsAtStartLastFrame = bIsAtEnd;
		}
	}

	UFUNCTION(NetFunction)
	void NetBroadCastEvent(ECounterWeightState CounterWeightState)
	{
		StateChanged.Broadcast(CounterWeightState);
	}

	void CheckEndState()
	{
		if (Progress > 0.998f)
		{
			bIsAtEnd = true;
		}

		else
		{
			bIsAtEnd = false;
		}

		if (bIsAtEnd != bIsAtEndLastFrame)
		{
			if (Progress > 0.998f)
			{
				if(HasAuthority())
				{
					NetBroadCastEvent(ECounterWeightState::IsAtEnd);
				}
			}

			else
			{
				if(HasAuthority())
				{
					NetBroadCastEvent(ECounterWeightState::IsInBetween);
				}
			}

			bIsAtEndLastFrame = bIsAtEnd;
		}
	}
}