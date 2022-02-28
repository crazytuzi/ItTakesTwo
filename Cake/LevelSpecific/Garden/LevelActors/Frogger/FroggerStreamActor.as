import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.Garden.LevelActors.Frogger.FroggerPlatformActor;
import Peanuts.Triggers.BoxShapeActor;

class AFroggerStreamActorHandler : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.bVisualizeComponent = true;

	UPROPERTY(DefaultComponent)
    UHazeDisableComponent DisableComponent;
	default DisableComponent.bActorIsVisualOnly = true;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 30000.f;

	// This component has be in view for the streams to update
	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent ActivationVisualizer;

	UPROPERTY(EditInstanceOnly)
	TArray<AFroggerStreamActor> Streams;

	float LastUpdatedGameTime = 0;
	float LastViewUpdated = 0;

	TPerPlayer<bool> bBothPlayersHasBegunPlay;

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
	{
		LastUpdatedGameTime = Time::GetGameTimeSeconds();
		for(AFroggerStreamActor Stream : Streams)
		{
			Stream.SetupPlatforms();
		}

		// The actor cant update until both sides has called the begin play
		if(Network::IsNetworked())
		{
			// so the liliypads stay in the same location
			if(HasControl())
				System::SetTimer(this, n"DelayedBeginPlay", Network::GetPingRoundtripSeconds() * 0.5f, false);
			else
				NetSetBeginPlay(1, Network::GetPingRoundtripSeconds());
		}
		else
		{
			bBothPlayersHasBegunPlay[0] = true;
			bBothPlayersHasBegunPlay[1] = true;
		}
	}

	UFUNCTION(NetFunction)
	private void NetSetBeginPlay(int Index, float Lag)
	{
		bBothPlayersHasBegunPlay[Index] = true;
		if(bBothPlayersHasBegunPlay[0] && bBothPlayersHasBegunPlay[1])
			LastUpdatedGameTime -= Lag;
	}

	UFUNCTION()
	void DelayedBeginPlay()
	{
		NetSetBeginPlay(0, Network::GetPingRoundtripSeconds());
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		for(AFroggerStreamActor Stream : Streams)
		{
			for(AFroggerPlatformActor PlatformActor : Stream.PlatformActors)
			{
				PlatformActor.EnableActor(this);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorPostDisabled()
	{
		for(AFroggerStreamActor Stream : Streams)
		{
			for(AFroggerPlatformActor PlatformActor : Stream.PlatformActors)
			{
				PlatformActor.DisableActor(this);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bBothPlayersHasBegunPlay[0] || !bBothPlayersHasBegunPlay[1])
			return;

		const float GameTime = Time::GetGameTimeSeconds();
		bool bIsInView = GameTime - LastViewUpdated < 1.f;
		if(!bIsInView)
		{
			for(auto Player : Game::GetPlayers())
			{
				if(SceneView::ViewFrustumBoxIntersection(Player, ActivationVisualizer))
				{
					bIsInView = true;
					LastViewUpdated = GameTime;
					break;
				}
			}
		}
		
		if(bIsInView)
		{	
			const float UpdateTimeAmount = GameTime - LastUpdatedGameTime;
			LastUpdatedGameTime = GameTime;
			for(AFroggerStreamActor Stream : Streams)
			{
				for(AFroggerPlatformActor PlatformActor : Stream.PlatformActors)
				{
					Stream.UpdatePlatform(PlatformActor, UpdateTimeAmount);
				}
			}
		}
	}	
}

UCLASS(Abstract)
class AFroggerStreamActor : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, Attach = RootComponent)
    UHazeSplineComponent Spline;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AFroggerPlatformActor> PlatformActorClass;

	UPROPERTY()
	int NumberOfPlatformsInRow = 1;

	UPROPERTY()
	float StartOffset = 0.0f;

	UPROPERTY()
	float PlatformOffset = 1700.0f;

	UPROPERTY()
	float SetOffset = 10.0f;

	UPROPERTY()
	float Speed = 500.0f;

	TArray<AFroggerPlatformActor> PlatformActors;
	float SplineLength = 0;

	void SetupPlatforms()
	{
		SplineLength = Spline.GetSplineLength();
		for(int i = 0; i < NumberOfPlatformsInRow; i++)
		{
			AFroggerPlatformActor PlatformActor = Cast<AFroggerPlatformActor>(SpawnActor(PlatformActorClass, Level = GetLevel()));
			PlatformActors.Add(PlatformActor);
			PlatformActor.MakeNetworked(this, i);

			FHazeSplineSystemPosition InitalSplinePosition;
			const float DistanceAlongSpline = StartOffset + (i * PlatformOffset);
			InitalSplinePosition.FromData(Spline, DistanceAlongSpline, true);
			PlatformActor.SplineMovement.ActivateSplineMovement(InitalSplinePosition);
			PlatformActor.SetActorLocation(InitalSplinePosition.GetWorldLocation());
		}
	}

	void UpdatePlatform(AFroggerPlatformActor PlatformActor, float DeltaTime)
	{
		float MoveAmount = Speed * DeltaTime;

		// We need to remove the looparound amount if it was a very long times since we updated the move
		const int MoveAmountWholeNumer = FMath::FloorToInt(MoveAmount / SplineLength);
		MoveAmount -= MoveAmountWholeNumer * SplineLength;

		FHazeSplineSystemPosition NewSplinePosition;
		bool bWarped = false;
		PlatformActor.SplineMovement.UpdateSplineMovementAndRestartAtEnd(MoveAmount, NewSplinePosition, bWarped);
		PlatformActor.SetActorLocation(NewSplinePosition.GetWorldLocation());

		PlatformActor.AcceleratedDownVelocity.SpringTo(PlatformActor.TargetHeight, PlatformActor.HeightChangeSpeed, PlatformActor.Bouncyness, DeltaTime);
		PlatformActor.Mesh.SetRelativeLocation(FVector(0,0, -PlatformActor.AcceleratedDownVelocity.Value));
	}
}

class UFroggerStreamVisualizerComponent : UActorComponent
{

};

class UFroggerStreamVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UFroggerStreamVisualizerComponent::StaticClass();

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		AFroggerStreamActor StreamActor = Cast<AFroggerStreamActor>(Component.Owner);

		for(int i = 0; i < StreamActor.NumberOfPlatformsInRow; i++ )
		{
			DrawWireSphere(
				(StreamActor.RootComponent.RelativeTransform.TransformPosition(StreamActor.Spline.GetLocationAtDistanceAlongSpline(StreamActor.StartOffset + i * StreamActor.PlatformOffset, ESplineCoordinateSpace::Local))), Radius = 200.f, Color = FLinearColor::Red);
		}
	}
};
