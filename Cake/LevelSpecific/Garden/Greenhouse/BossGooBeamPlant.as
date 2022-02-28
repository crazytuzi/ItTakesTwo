import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;
import Cake.Environment.GPUSimulations.PaintablePlane;

class ABossGooBeamPlant : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshBody;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bDisabledAtStart = true;

 	UPROPERTY(EditInstanceOnly)
	APaintablePlane PaintablePlane;

	UPROPERTY(Category = "Goo")
	FLinearColor GooColor = FLinearColor(0.f, 0.f, 1.f, 0.f);

	UPROPERTY(Category = "Goo")
	float ImpactCleanRadiusCody = 200.f;
	UPROPERTY(Category = "Goo")
	float ImpactCleanRadiusActor = 525.f;

	bool ActiveFollowPattern = false;
	FVector ImpactStartLocation;
	FVector ImpactLocation;
	FVector TargetLocation;
	const float LerpTimeCody = 0.45; 
	const float LerpTimeActor = 0.45; 
	float DelayTime;

	bool bDebugDisableGooSpiting = false;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent GooBeam;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent GooBeamImpact;
	AHazePlayerCharacter PlayerTarget;
	AActor PatternActorToFollow;

	float AllowPaintTimer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetControlSide(Game::May);
	}

	UFUNCTION(BlueprintCallable)
	void StartGooPattern(AActor ActorToFollow)
	{
		if(HasControl())
		{
			NetStartGooPattern(ActorToFollow);
		}
	}
	UFUNCTION(NetFunction)
	void NetStartGooPattern(AActor ActorToFollow)
	{
		EnableActor(nullptr);
		ImpactStartLocation = ActorToFollow.GetActorLocation();
		TargetLocation = ActorToFollow.GetActorLocation();
		ImpactLocation = ActorToFollow.GetActorLocation();
		PatternActorToFollow = ActorToFollow;
		ActiveFollowPattern = true;
		GooBeam.Activate();
		GooBeamImpact.Activate();
	}

	UFUNCTION(BlueprintCallable)
	void StopGooBeam()
	{
		if(this.HasControl())
		{
			NetStopGooBeam();
		}
	}
	UFUNCTION(NetFunction)
	void NetStopGooBeam()
	{
		ActiveFollowPattern = false;
		GooBeam.Deactivate();
		GooBeamImpact.Deactivate();
		
		System::SetTimer(this, n"HideActor", 3.0f, false);
	}
	UFUNCTION()
	void HideActor()
	{
		if(IsActorDisabled() == false)
			DisableActor(nullptr);
	}

	UFUNCTION()
	void DebugDisableGooSpiting()
	{
		bDebugDisableGooSpiting = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bDebugDisableGooSpiting == true)
			return;

		if(ActiveFollowPattern == true)
		{
			PaintablePlane.LerpAndDrawTexture(ImpactLocation, ImpactCleanRadiusActor, GooColor,  FLinearColor(0.f, 0.f, 25.0f, 0.f) * DeltaTime, true, nullptr, true, FLinearColor(1.45f,1.45f,1.45f));
			float Alpha = DelayTime/LerpTimeActor;
			ImpactLocation = FMath::Lerp(TargetLocation, ImpactStartLocation, Alpha);

			GooBeam.SetNiagaraVariableVec3("User.BeamEnd", ImpactLocation);
			GooBeam.SetNiagaraVariableVec3("User.BeamStart", GetActorLocation());
			GooBeamImpact.SetWorldLocation(ImpactLocation);

			DelayTime -=DeltaTime;
			if(DelayTime <= 0)
			{
				if(HasControl())
				{
					UHazeCrumbComponent CrumbComb = UHazeCrumbComponent::Get(Game::GetMay());
					FHazeDelegateCrumbParams CrumbParams;
					CrumbParams.AddVector(n"ActorLocation", PatternActorToFollow.GetActorLocation());
					CrumbComb.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_PaintActor"), CrumbParams);
				}
				else
				{
					DelayTime = 0;
				}
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_PaintActor(const FHazeDelegateCrumbData& CrumbData)
	{
		DelayTime = LerpTimeActor;
		TargetLocation = CrumbData.GetVector(n"ActorLocation");
		ImpactStartLocation = ImpactLocation;
	}
}

