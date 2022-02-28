//  
// import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;
//  
//  class USwarmHitAndRunSearchSplineCapability : USwarmBehaviourCapability
//  {
// 	default AssignedState = ESwarmBehaviourState::Search;
//  
//  	UFUNCTION(BlueprintOverride)
//  	EHazeNetworkActivation ShouldActivate() const
//  	{
// 		if (BehaviourComp.HasBehaviourBeenFinalized())
// 			return EHazeNetworkActivation::DontActivate;
// 
//  		if (!MoveComp.HasSplineToFollow())
//  			return EHazeNetworkActivation::DontActivate;
// 
// 		return EHazeNetworkActivation::ActivateLocal;
//  	}
//  
//  	UFUNCTION(BlueprintOverride)
//  	EHazeNetworkDeactivation ShouldDeactivate() const
//  	{
// 		if (BehaviourComp.HasBehaviourBeenFinalized())
// 			return EHazeNetworkDeactivation::DeactivateLocal;
// 
//  		if (!MoveComp.HasSplineToFollow())
// 			return EHazeNetworkDeactivation::DeactivateLocal;
// 
//  		return EHazeNetworkDeactivation::DontDeactivate;
//  	}
//  
//  	UFUNCTION(BlueprintOverride)
//  	void OnActivated(FCapabilityActivationParams ActivationParams)
//  	{
// 		SkelMeshComp.PushSwarmAnimSettings(
// 			Settings.HitAndRun.Search.AnimSettingsDataAsset,
// 			this
// 		);
// 
// 		BehaviourComp.NotifyStateChanged();
//  	}
// 
// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
// 		SkelMeshComp.RemoveSwarmAnimSettings(this);
// 	}
// 
//  	UFUNCTION(BlueprintOverride)
//  	void TickActive(float DeltaSeconds)
//  	{
// 		MoveComp.LerpAlongSpline(
// 			Settings.HitAndRun.Search.InterpStepSize,
// 			Settings.HitAndRun.Search.LerpSpeed,
// 			Settings.HitAndRun.Search.bConstantLerpSpeed,
// 			DeltaSeconds
// 		);
// 	}
// 
//  }
// 
// 
// 
// 
// 
// 
// 
