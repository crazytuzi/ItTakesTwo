import Peanuts.Triggers.PlayerTrigger;
import Vino.PlayerHealth.PlayerHealthStatics;

UCLASS(Abstract)
class MoshPitMole : AHazeCharacter
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bDisabledAtStart = true;

	UPROPERTY()
	UAnimSequence LoopAnimation;

	UPROPERTY()
	APlayerTrigger ActivateTrigger;
	UPROPERTY()
	APlayerTrigger DisableTrigger;
	
	AHazePlayerCharacter Target;
	float DistanceToMay;
	float DistanceToCody;
	float FollowDuration = 3.f;
	FHazeAcceleratedRotator AccRotation;
	UPROPERTY()
	float TurnSpeedMultiplier = 1.95f;
	UPROPERTY()
	float AnimationStartOffset = 0;

	bool Active = false;
	bool DoOnce = false;
	FRotator LookAtRotation;
	float YawLerp;


	bool MayEnteredDisableTrigger = false;
	bool CodyEnteredDisableTrigger = false;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AccRotation.SnapTo(Mesh.GetWorldRotation());
		if(ActivateTrigger != nullptr)
			ActivateTrigger.OnPlayerEnter.AddUFunction(this, n"ActivateMoshPitMole");
		if(DisableTrigger != nullptr)
			DisableTrigger.OnPlayerEnter.AddUFunction(this, n"DisableMoshPitMole");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!Active)
			return;

		DistanceToCody = (this.GetActorLocation() - Game::GetCody().GetActorLocation()).Size();
		DistanceToMay = (this.GetActorLocation() - Game::GetMay().GetActorLocation()).Size();

		if(DistanceToCody < 7000 or DistanceToMay < 7000)
		{
			if(DistanceToMay > DistanceToCody)
			{
				if(Game::GetCody().IsPlayerDead())
				{
					Target = Game::GetMay();
				}
				else
				{
					Target = Game::GetCody();
				}
			}
			else
			{
				if(Game::GetMay().IsPlayerDead())
				{
					Target = Game::GetCody();
				}
				else
				{
					Target = Game::GetMay();
				}
			}


			FVector Direction = Target.GetActorLocation() - this.GetActorLocation();
			LookAtRotation = Math::MakeRotFromX(Direction);
			YawLerp = FMath::Lerp(YawLerp, LookAtRotation.Yaw, DeltaSeconds * TurnSpeedMultiplier);
			Mesh.SetWorldRotation(FRotator(Mesh.GetWorldRotation().Pitch, YawLerp, Mesh.GetWorldRotation().Roll));


			//FVector DirToPlayer = Target.GetActorLocation() - this.GetActorLocation();
			//FRotator CurRot = AccRotation.AccelerateTo(DirToPlayer.Rotation(), FollowDuration, DeltaSeconds * TurnSpeedMultiplier);

			//Mesh.SetWorldRotation(CurRot);
		}
	}

	UFUNCTION()
	void ActivateMoshPitMole(AHazePlayerCharacter Player)
	{
		if(DoOnce == true)
			return;

		EnableActor(nullptr);
		DoOnce = true;
		Active = true;
		FHazeAnimationDelegate OnBlendedIn;
		FHazeAnimationDelegate OnBlendingOut;
		PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = LoopAnimation, bLoop = true, BlendType = EHazeBlendType::BlendType_Inertialization, BlendTime = 0.2f, PlayRate = 1.0f, StartTime = AnimationStartOffset, bPauseAtEnd = false);
	}

	UFUNCTION()
	void DisableMoshPitMole(AHazePlayerCharacter Player)
	{
		if(Active != true)
			return;
			
		if(Player == Game::GetCody())
		{
			CodyEnteredDisableTrigger = true;
			if(MayEnteredDisableTrigger == true)
			{
				Active = false;
				DisableActor(nullptr);
			}
		}
		if(Player == Game::GetMay())
		{
			MayEnteredDisableTrigger = true;
			if(CodyEnteredDisableTrigger == true)
			{
				Active = false;
				DisableActor(nullptr);
			}
		}
	}
}