﻿using MathNet.Numerics.LinearAlgebra;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CudaLearn
{

    public class ThresholdLayerConfiguration : LayerConfiguration
    {
        public ThresholdLayerConfiguration()
            : this(0.0f)
        { }

        public ThresholdLayerConfiguration(float threshold)
            : base(LayerType.Threshold)
        {
            this.Threshold = threshold;
        }

        public float Threshold { get; set; }
    }

    /// <summary>
    /// ThresholdLayer
    ///     Outputs 1 if value in input is above threshold, 0 otherwise.
    ///     The defult threshold = 0, which means positive values would become 1 and 
    ///     negative or 0, would become 0
    ///     
    /// y = 1 if x greater than Threshold
    /// y = 0 if x less or equal than Threshold
    /// 
    /// y' = don't differenciable
    /// </summary>
    public class ThresholdLayer : NeuronLayer<ThresholdLayerConfiguration>
    {
        public ThresholdLayer()
            : this(new ThresholdLayerConfiguration())
        { }

        public ThresholdLayer(ThresholdLayerConfiguration param)
            : base(param)
        { }

        protected override float ForwardCpu(IList<Blob> bottom, IList<Blob> top)
        {
            var bottomData = bottom[0].Data;
            var topData = top[0].Data;

            var threshold = this.Parameters.Threshold;

            int count = bottom[0].Count;
            bottomData.MapIndexed((i, v) => (v > threshold) ? 1.0f : 0.0f, topData, Zeros.Include);

            return 0;
        }
    }
}