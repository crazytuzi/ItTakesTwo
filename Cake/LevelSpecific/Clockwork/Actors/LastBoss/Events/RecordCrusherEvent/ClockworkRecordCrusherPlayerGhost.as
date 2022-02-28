import Vino.Movement.MovementSystemTags;
import Vino.PlayerHealth.PlayerHealthStatics;

struct FRecordCrusherGhostKey
{
	float Time = 0.f;
	FTransform Transform;
	bool bDashing = false;
	bool bDead = false;
	bool bFalling = false;

	void BlendFrom(FRecordCrusherGhostKey A, FRecordCrusherGhostKey B, float Alpha)
	{
		float InvAlpha = 1.f - Alpha; 
		Time = A.Time * InvAlpha + B.Time * Alpha;
		Transform.Blend(A.Transform, B.Transform, Alpha);
		bDashing = A.bDashing || B.bDashing;
		bDead = A.bDead || B.bDead;
		bFalling = A.bFalling || B.bFalling;
	}
};

class AClockworkRecordCrusherPlayerGhost : AHazeCharacter
{
	default CapsuleComponent.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent RewindMesh;

	UPROPERTY()
	float RecordInterval = 0.05f;

	UPROPERTY()
	bool bDontRecordVerticalMovement = true;

	UPROPERTY()
	AHazePlayerCharacter RecordPlayer;


	default ActorEnableCollision = false;

	private float StartZ = 0.f;

	private TArray<FRecordCrusherGhostKey> Recording;
	private bool bRecording = false;
	private float RecordIntervalTimer = 0.f;
	private float RecordStartTimer = 0.f;
	private float RecordedDuration = 0.f;

	private bool bPlaying = false;
	private float PlayTimer = 0.f;
	private float PlayDuration = 0.f;
	private int PlayIndex = 0;

	private bool bReversing = false;
	private float ReverseTimer = 0.f;
	private float ReverseDuration = 0.f;
	private int ReverseIndex = 0;

	float GetTotalRecordedDuration()
	{
		return RecordedDuration;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bRecording)
		{
			RecordIntervalTimer += DeltaTime;
			RecordStartTimer += DeltaTime;

			if (RecordIntervalTimer >= RecordInterval)
				RecordKey();

			ActorTransform = RecordPlayer.Mesh.WorldTransform;
		}

		if (bPlaying)
		{
			PlayTimer += DeltaTime;
			PlayTimer = FMath::Clamp(PlayTimer, 0.f, PlayDuration);

			float PlayPct = PlayTimer / PlayDuration;
			float RecordTime = PlayPct * RecordedDuration;

			FRecordCrusherGhostKey CurrentPosition;

			while (true)
			{
				int CurIndex = PlayIndex;
				int NextIndex = FMath::Min(PlayIndex + 1, Recording.Num() - 1);
				float ATime = Recording[CurIndex].Time;
				float BTime = Recording[NextIndex].Time;

				ensure(ATime <= RecordTime);
				if (BTime < RecordTime && (PlayIndex+1) < Recording.Num())
				{
					// Advance to the next recorded key if our time is beyond the current key
					PlayIndex += 1;
					continue;
				}

				float BlendAlpha = 1.f;
				if (ATime != BTime)
					BlendAlpha = FMath::Clamp((RecordTime - ATime) / (BTime - ATime), 0.f, 1.f);

				CurrentPosition.BlendFrom(Recording[CurIndex], Recording[NextIndex], BlendAlpha);
				break;
			}

			ApplyKeyMovement(DeltaTime, CurrentPosition, bReverse = false);
		}

		if (bReversing)
		{
			ReverseTimer -= DeltaTime;
			ReverseTimer = FMath::Clamp(ReverseTimer, 0.f, ReverseDuration);

			float ReversePct = ReverseTimer / ReverseDuration;
			float RecordTime = ReversePct * RecordedDuration;

			FRecordCrusherGhostKey CurrentPosition;

			while (true)
			{
				int CurIndex = ReverseIndex;
				int PrevIndex = FMath::Max(ReverseIndex - 1, 0);
				float ATime = Recording[PrevIndex].Time;
				float BTime = Recording[CurIndex].Time;

				if (ATime > RecordTime && (ReverseIndex-1) >= 0)
				{
					// Reverse to the previous entry
					ReverseIndex -= 1;
					continue;
				}

				float BlendAlpha = 1.f;
				if (ATime != BTime)
					BlendAlpha = FMath::Clamp((RecordTime - ATime) / (BTime - ATime), 0.f, 1.f);

				CurrentPosition.BlendFrom(Recording[PrevIndex], Recording[CurIndex], BlendAlpha);
				break;
			}

			ApplyKeyMovement(DeltaTime, CurrentPosition, bReverse = true);

			if (ReverseTimer <= 0.f)
			{
				bReversing = false;
				StopAllSlotAnimations();
			}
		}
	}

	void RecordKey()
	{
		FRecordCrusherGhostKey Key;
		Key.Time = RecordStartTimer;
		Key.Transform = RecordPlayer.Mesh.WorldTransform;
		Key.bDashing = RecordPlayer.IsAnyCapabilityActive(MovementSystemTags::Dash);
		Key.bDead = RecordPlayer.IsPlayerDead();
		Key.bFalling = Key.Transform.Location.Z < StartZ;

		if (bDontRecordVerticalMovement && !Key.bFalling)
		{
			FVector FlatLocation = Key.Transform.Location;
			FlatLocation.Z = StartZ;
			Key.Transform.SetLocation(FlatLocation);
		}

		Recording.Add(Key);
	}

	void ApplyKeyMovement(float DeltaTime, FRecordCrusherGhostKey Key, bool bReverse)
	{
		FVector Delta = Key.Transform.Location - ActorLocation;
		SetActorTransform(Key.Transform);

        FHazeRequestLocomotionData AnimationRequest;
        AnimationRequest.LocomotionAdjustment.DeltaTranslation = Delta;
        AnimationRequest.LocomotionAdjustment.WorldRotation = ActorQuat;
 		AnimationRequest.WantedVelocity = Delta / DeltaTime;
        AnimationRequest.WantedWorldTargetDirection = ActorQuat.ForwardVector;
        AnimationRequest.WantedWorldFacingRotation = ActorQuat;

		if (bReverse)
			AnimationRequest.WantedVelocity *= -1.f;

		AnimationRequest.AnimationTag = n"RecordCrusherPlayerGhost";
		if (Key.bDashing)
			AnimationRequest.SubAnimationTag = n"Dash";
		else if (Delta.IsNearlyZero())
			AnimationRequest.SubAnimationTag = n"Idle";
		else
			AnimationRequest.SubAnimationTag = n"Movement";

		SetAnimBoolParam(n"MovingReverse", bReverse);
        RequestLocomotion(AnimationRequest);
	}

	void StartRecording(AHazePlayerCharacter Player)
	{
		SetActorHiddenInGame(true);
		RecordPlayer = Player;
		StartZ = Player.Mesh.WorldLocation.Z;

		Recording.Empty();

		bRecording = true;
		RecordStartTimer = 0.f;
		RecordIntervalTimer = 0.f;
		RecordKey();
	}

	void StopRecording()
	{
		RecordKey();
		bRecording = false;
		RecordedDuration = RecordStartTimer;
	}

	void Play(float Duration)
	{
		SetActorHiddenInGame(false);

		bReversing = false;

		bPlaying = true;
		PlayTimer = 0.f;
		PlayDuration = Duration;
		PlayIndex = 0;

		//Mesh.SetHiddenInGame(false);
		RewindMesh.SetHiddenInGame(true);

		StopAllSlotAnimations();

		SetActorTransform(Recording[0].Transform);
	}

	void PlayReverse(float Duration)
	{
		SetActorHiddenInGame(false);

		bPlaying = false;

		bReversing = true;
		ReverseTimer = Duration;
		ReverseDuration = Duration;
		ReverseIndex = Recording.Num() - 1;

		//Mesh.SetHiddenInGame(true);
		RewindMesh.SetHiddenInGame(true);

		SetActorTransform(Recording.Last().Transform);
	}
};