import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;
import Cake.LevelSpecific.Music.Cymbal.Cymbal;
import Cake.LevelSpecific.Music.LevelMechanics.SpeakerPushManager;

class ASpeakerPush : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent Arrow;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent PushBackDirection;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent MainLaser;


	UPROPERTY()
	ASpeakerPushManager SpeakerPushManager;
	

	UPROPERTY()
	float MainLaserDefaultLength = 200.f;

	UPROPERTY()
	float PushBackMultiplier = 20;

	bool bShouldBeActive = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MainLaser.SetNiagaraVariableVec3("BeamEnd", FVector(0.f, 0.f, MainLaserDefaultLength));
		MainLaser.SetNiagaraVariableVec3("BeamEnd", FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		MainLaser.SetNiagaraVariableVec3("BeamEnd", FVector(0.f, 0.f, MainLaserDefaultLength));
		MainLaser.SetNiagaraVariableVec3("BeamEnd", FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bShouldBeActive)
			return;
		
		FVector Start = Arrow.GetWorldLocation();
		FVector End = Start + Arrow.ForwardVector * MainLaserDefaultLength;
		FQuat Rot = FVector(End - Start).ToOrientationQuat();
		TArray<AActor> ActorsToIgnore;
		TArray<FHitResult> HitResult;
		Trace::CapsuleTraceMultiAllHitsByChannel(Start, End, Rot, 30.f, 30.f, ETraceTypeQuery::Camera, false, ActorsToIgnore, HitResult, -1.f);


		bool bHitAnyPlayer = false;
		bool bHitCymbal = false;
		for (FHitResult Hit : HitResult)
		{			
			if (Hit.GetActor() == Game::GetCody())
			{
				AHazePlayerCharacter Cody = Cast<AHazePlayerCharacter>(Hit.GetActor());
				if (Cody != nullptr)
				{
					UCymbalComponent Cymbal = UCymbalComponent::Get(Cody);

					FVector Dir = Cody.GetActorLocation() - GetActorLocation();
					Dir.Normalize();
					float CymbalDot = Dir.DotProduct(Cody.GetActorForwardVector());
							
					if (Cymbal.bShieldActive && CymbalDot < -.5f)
					{
						float DistanceToCody = FVector(Cody.GetActorLocation() - GetActorLocation()).Size();
						MainLaser.SetNiagaraVariableVec3("BeamEnd", FVector(0.f, 0.f, DistanceToCody));
						bHitAnyPlayer = true;
					
						bHitCymbal = true;
						//continue;
					} else
					{
						SpeakerPushManager.PushPlayerCody(Game::GetCody());
						bHitCymbal = false;
					}				
				}
			}
			
			if (Hit.GetActor() == Game::GetMay())
			{
				if (bHitCymbal)
					continue;

				SpeakerPushManager.PushPlayerMay(Game::GetMay());
				bHitAnyPlayer = true;
				//continue;
			}
		}

		if (!bHitAnyPlayer)
		{
			MainLaser.SetNiagaraVariableVec3("BeamEnd", FVector(0.f, 0.f, MainLaserDefaultLength));
		
		}
	}

	UFUNCTION()
	void TurnOffSpeaker()
	{
		bShouldBeActive = false;
		Mesh.SetHiddenInGame(true);
		MainLaser.Deactivate();
	
	}
}