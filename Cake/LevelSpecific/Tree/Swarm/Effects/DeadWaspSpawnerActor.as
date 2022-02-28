
UCLASS(HideCategories = "Activation Replication Input Cooking LOD Actor")
class ADeadWaspSpawnerActor : ANiagaraActor
{
//	float IntermediateSpawnRate = 1000000.f;
//	float IntermediateDeltaTime = 0.000001f;

	float IntermediateSpawnRate = 100000.f;
	float IntermediateDeltaTime = 0.00001f;
	float HalfIntermediateDt = 0.000005f;

	// default NiagaraComponent.Asset = Asset("/Game/Effects/Gameplay/Wasps/MiniWaspParticles.MiniWaspParticles"); 
//	default NiagaraComponent.SetForceSolo(true);
	// default NiagaraComponent.bForceSolo = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpawnDeadWasp_Finalize();
	}

	// 1st step
	UFUNCTION()
	void SpawnDeadWasp_Init()
	{
		NiagaraComponent.SetNiagaraVariableFloat("User.SpawnRate", IntermediateSpawnRate);
	}

	// 2nd step
	UFUNCTION()
	void SpawnDeadWasp_Intermediate(const FVector& Loc, const FQuat& Rot, const FVector& LinVel, const FVector& AngVel)
	{
//		const FVector TestLocation = FVector(1000, 2500.f, 500.f);
//		const FQuat TestQuat =FQuat(FVector::UpVector, PI/4.f); 
//		System::DrawDebugCoordinateSystem(TestLocation, TestQuat.Rotator(), 1000.f, 5.f);
//		System::DrawDebugPoint(TestLocation, 10.f, FLinearColor::Red, 5.f);
//		NiagaraComponent.SetNiagaraVariableVec3("User.Position", Loc);
//		NiagaraComponent.SetNiagaraVariableQuat("User.Rotation", TestQuat);

		NiagaraComponent.SetNiagaraVariableVec3("User.Position", Loc);
		NiagaraComponent.SetNiagaraVariableQuat("User.Rotation", Rot);
		NiagaraComponent.SetNiagaraVariableVec3("User.Velocity", LinVel);
 		const float AngVelMagnitude = AngVel.Size();
		if(AngVelMagnitude != 0.f)
		{
			const FVector AngVelNormalized = AngVel / AngVelMagnitude; 
			FVector4 AngVel_VEC4 = FVector4(AngVelNormalized, AngVelMagnitude);
			NiagaraComponent.SetNiagaraVariableVec4("User.AngularVelocity", AngVel_VEC4);
		} 
		else
		{
			FVector4 AngVel_VEC4 = FVector4(FVector::ZeroVector, 0.f);
			NiagaraComponent.SetNiagaraVariableVec4("User.AngularVelocity", AngVel_VEC4);
		}

//		NiagaraComponent.AdvanceSimulation(1, HalfIntermediateDt);
//		NiagaraComponent.AdvanceSimulation(1, HalfIntermediateDt);
		NiagaraComponent.AdvanceSimulation(1, IntermediateDeltaTime);
	}

	// 3rd step
	UFUNCTION()
	void SpawnDeadWasp_Finalize()
	{
		NiagaraComponent.SetNiagaraVariableFloat("User.SpawnRate", 0.f);
	}
}