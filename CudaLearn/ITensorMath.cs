﻿using System;
using System.Collections.Generic;
using System.Diagnostics.Contracts;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CudaLearn
{
    public enum BlasTranspose
    {
        None,
        Transpose
    }

    [ContractClass(typeof(ITensorMathContract))]
    public interface ITensorMath
    {
        void Gemm(BlasTranspose transA, BlasTranspose transB, int m, int n, int k, double alpha, ArraySlice<double> a, ArraySlice<double> b, float beta, ArraySlice<double> c);
        void Gemv(BlasTranspose transA, int m, int n, double alpha, ArraySlice<double> a, ArraySlice<double> x, double beta, ArraySlice<double> y);
        void Axpy(double alpha, ArraySlice<double> x, ArraySlice<double> y);
        void Axpby(double alpha, ArraySlice<double> x, double beta, ArraySlice<double> y);
        
        void Set(double alpha, ArraySlice<double> y);
        void Set(int alpha, ArraySlice<double> y);

        void Copy(ArraySlice<double> x, ArraySlice<double> y);

        void Add(double alpha, ArraySlice<double> y);
        void Add(ArraySlice<double> a, ArraySlice<double> b);
        void Substract(ArraySlice<double> a, ArraySlice<double> b);
        void Multiply(ArraySlice<double> a, ArraySlice<double> b);
        void Divide(ArraySlice<double> a, ArraySlice<double> b);
        void Powx(ArraySlice<double> a, ArraySlice<double> b);
        void Square(ArraySlice<double> a, ArraySlice<double> b);
        void Exp(ArraySlice<double> a, ArraySlice<double> b);
        void Abs(ArraySlice<double> a, ArraySlice<double> b);

        double Dot(ArraySlice<double> x, ArraySlice<double> y);
        double Dot(ArraySlice<double> x, int incx, ArraySlice<double> y, int incy);

        double Asum(ArraySlice<double> x);

        void Scale(double alpha, ArraySlice<double> x);
        void Scale(double alpha, ArraySlice<double> x, ArraySlice<double> y);
    }

    [ContractClassFor(typeof(ITensorMath))]
    internal abstract class ITensorMathContract : ITensorMath
    {

        void ITensorMath.Gemm(BlasTranspose transA, BlasTranspose transB, int m, int n, int k, double alpha, ArraySlice<double> a, ArraySlice<double> b, float beta, ArraySlice<double> c)
        {
            Contract.Requires(m > 0 && n > 0 && k > 0);
            
            Contract.Requires(a != null);
            Contract.Requires(b != null);
            Contract.Requires(c != null);
            Contract.Requires(a.Length == m * k);
            Contract.Requires(b.Length == k * n);
            Contract.Requires(c.Length == m * n);
            
            Contract.Requires(!double.IsNaN(alpha) && !double.IsNaN(beta));
            Contract.Requires(Contract.ForAll(a, aa => !double.IsNaN(aa)));
            Contract.Requires(Contract.ForAll(b, bb => !double.IsNaN(bb)));
            Contract.Requires(Contract.ForAll(c, cc => !double.IsNaN(cc)));

            Contract.Ensures(Contract.ForAll(c, cc => !double.IsNaN(cc)));
        }

        void ITensorMath.Gemv(BlasTranspose transA, int m, int n, double alpha, ArraySlice<double> a, ArraySlice<double> x, double beta, ArraySlice<double> y)
        {
            Contract.Requires(a != null);
            Contract.Requires(x != null);
            Contract.Requires(y != null);
            Contract.Requires(m > 0 && n > 0);
            Contract.Requires(a.Length == m * n);
            Contract.Requires(!double.IsNaN(alpha) && !double.IsNaN(beta));

            Contract.Requires(Contract.ForAll(a, aa => !double.IsNaN(aa)));
            Contract.Requires(Contract.ForAll(x, xx => !double.IsNaN(xx)));
            Contract.Requires(Contract.ForAll(y, yy => !double.IsNaN(yy)));

            Contract.Ensures(Contract.ForAll(y, yy => !double.IsNaN(yy)));
        }

        void ITensorMath.Axpy(double alpha, ArraySlice<double> x, ArraySlice<double> y)
        {
            Contract.Requires(x != null);
            Contract.Requires(y != null);
            Contract.Requires(!double.IsNaN(alpha));
            Contract.Requires(x.Length == y.Length);

            Contract.Requires(Contract.ForAll(x, xx => !double.IsNaN(xx)));
            Contract.Requires(Contract.ForAll(y, yy => !double.IsNaN(yy)));

            Contract.Ensures(Contract.ForAll(y, yy => !double.IsNaN(yy)));
        }

        void ITensorMath.Axpby(double alpha, ArraySlice<double> x, double beta, ArraySlice<double> y)
        {
            Contract.Requires(x != null);
            Contract.Requires(y != null);
            Contract.Requires(!double.IsNaN(alpha) && !double.IsNaN(beta));
            Contract.Requires(x.Length == y.Length);

            Contract.Requires(Contract.ForAll(x, xx => !double.IsNaN(xx)));
            Contract.Requires(Contract.ForAll(y, yy => !double.IsNaN(yy)));

            Contract.Ensures(Contract.ForAll(y, yy => !double.IsNaN(yy)));
        }

        void ITensorMath.Set(double alpha, ArraySlice<double> y)
        {
            Contract.Requires(y != null);
            Contract.Requires(!double.IsNaN(alpha));
            Contract.Ensures(Contract.ForAll(y, x => x == alpha));
        }

        void ITensorMath.Set(int alpha, ArraySlice<double> y)
        {
            Contract.Requires(y != null);
            Contract.Requires(!double.IsNaN(alpha));
            Contract.Ensures(Contract.ForAll(y, x => x == alpha));
        }

        void ITensorMath.Copy(ArraySlice<double> x, ArraySlice<double> y)
        {
            Contract.Requires(x != null);
            Contract.Requires(y != null);
            Contract.Requires(x.Length == y.Length);
        }
        
        void ITensorMath.Add(double alpha, ArraySlice<double> y)
        {
            Contract.Requires(y != null);

            Contract.Requires(Contract.ForAll(y, yy => !double.IsNaN(yy)));
            Contract.Ensures(Contract.ForAll(y, yy => !double.IsNaN(yy)));
        }

        void ITensorMath.Add(ArraySlice<double> a, ArraySlice<double> b)
        {
            Contract.Requires(a != null);
            Contract.Requires(b != null);
            Contract.Requires(a.Length == b.Length);

            Contract.Requires(Contract.ForAll(a, xx => !double.IsNaN(xx)));
            Contract.Requires(Contract.ForAll(b, yy => !double.IsNaN(yy)));

            Contract.Ensures(Contract.ForAll(b, bb => !double.IsNaN(bb)));
        }

        void ITensorMath.Substract(ArraySlice<double> a, ArraySlice<double> b)
        {
            Contract.Requires(a != null);
            Contract.Requires(b != null);
            Contract.Requires(a.Length == b.Length);

            Contract.Requires(Contract.ForAll(a, xx => !double.IsNaN(xx)));
            Contract.Requires(Contract.ForAll(b, yy => !double.IsNaN(yy)));

            Contract.Ensures(Contract.ForAll(b, bb => !double.IsNaN(bb)));
        }

        void ITensorMath.Multiply(ArraySlice<double> a, ArraySlice<double> b)
        {
            Contract.Requires(a != null);
            Contract.Requires(b != null);
            Contract.Requires(a.Length == b.Length);

            Contract.Requires(Contract.ForAll(a, xx => !double.IsNaN(xx)));
            Contract.Requires(Contract.ForAll(b, yy => !double.IsNaN(yy)));

            Contract.Ensures(Contract.ForAll(b, bb => !double.IsNaN(bb)));
        }

        void ITensorMath.Divide(ArraySlice<double> a, ArraySlice<double> b)
        {
            Contract.Requires(a != null);
            Contract.Requires(b != null);
            Contract.Requires(a.Length == b.Length);

            Contract.Requires(Contract.ForAll(a, xx => !double.IsNaN(xx)));
            Contract.Requires(Contract.ForAll(b, yy => !double.IsNaN(yy)));

            Contract.Ensures(Contract.ForAll(b, bb => !double.IsNaN(bb)));
        }

        void ITensorMath.Powx(ArraySlice<double> a, ArraySlice<double> b)
        {
            Contract.Requires(a != null);
            Contract.Requires(b != null);
            Contract.Requires(a.Length == b.Length);

            Contract.Requires(Contract.ForAll(a, xx => !double.IsNaN(xx)));
            Contract.Requires(Contract.ForAll(b, yy => !double.IsNaN(yy)));

            Contract.Ensures(Contract.ForAll(b, bb => !double.IsNaN(bb)));
        }

        void ITensorMath.Square(ArraySlice<double> a, ArraySlice<double> b)
        {
            Contract.Requires(a != null);
            Contract.Requires(b != null);
            Contract.Requires(a.Length == b.Length);

            Contract.Requires(Contract.ForAll(a, xx => !double.IsNaN(xx)));
            Contract.Requires(Contract.ForAll(b, yy => !double.IsNaN(yy)));

            Contract.Ensures(Contract.ForAll(b, x => x >= 0));
            Contract.Ensures(Contract.ForAll(b, bb => !double.IsNaN(bb)));
        }

        void ITensorMath.Exp(ArraySlice<double> a, ArraySlice<double> b)
        {
            Contract.Requires(a != null);
            Contract.Requires(b != null);
            Contract.Requires(a.Length == b.Length);

            Contract.Requires(Contract.ForAll(a, xx => !double.IsNaN(xx)));
            Contract.Requires(Contract.ForAll(b, yy => !double.IsNaN(yy)));

            Contract.Ensures(Contract.ForAll(b, bb => !double.IsNaN(bb)));
        }

        void ITensorMath.Abs(ArraySlice<double> a, ArraySlice<double> b)
        {
            Contract.Requires(a != null);
            Contract.Requires(b != null);
            Contract.Requires(a.Length == b.Length);

            Contract.Requires(Contract.ForAll(a, xx => !double.IsNaN(xx)));
            Contract.Requires(Contract.ForAll(b, yy => !double.IsNaN(yy)));

            Contract.Ensures(Contract.ForAll(b, xx => xx >= 0));
            Contract.Ensures(Contract.ForAll(b, bb => !double.IsNaN(bb)));
        }

        double ITensorMath.Dot(ArraySlice<double> x, ArraySlice<double> y)
        {
            Contract.Requires(x != null);
            Contract.Requires(y != null);
            Contract.Requires(x.Length == y.Length);
            
            Contract.Requires(Contract.ForAll(x, xx => !double.IsNaN(xx)));
            Contract.Requires(Contract.ForAll(y, yy => !double.IsNaN(yy)));

            Contract.Ensures(!double.IsNaN(Contract.Result<double>()));
            return 0;
        }

        double ITensorMath.Dot(ArraySlice<double> x, int incx, ArraySlice<double> y, int incy)
        {
            Contract.Requires(incx > 0 && incy > 0);

            Contract.Requires(x != null);
            Contract.Requires(y != null);
            Contract.Requires(x.Length == y.Length);

            Contract.Requires(Contract.ForAll(x, xx => !double.IsNaN(xx)));
            Contract.Requires(Contract.ForAll(y, yy => !double.IsNaN(yy)));

            Contract.Ensures(!double.IsNaN(Contract.Result<double>()));

            return 0;
        }

        double ITensorMath.Asum(ArraySlice<double> x)
        {
            Contract.Requires(x != null);
            Contract.Requires(Contract.ForAll(x, xx => !double.IsNaN(xx)));

            Contract.Ensures(!double.IsNaN(Contract.Result<double>()));
            Contract.Ensures(Contract.ForAll(x, xx => !double.IsNaN(xx)));

            Contract.Ensures(Contract.Result<double>() >= 0);
            return 0;
        }

        void ITensorMath.Scale(double alpha, ArraySlice<double> x)
        {
            Contract.Requires(x != null);
            Contract.Requires(!double.IsNaN(alpha));
            Contract.Requires(Contract.ForAll(x, xx => !double.IsNaN(xx)));
            
            Contract.Ensures(Contract.ForAll(x, xx => !double.IsNaN(xx)));
        }

        void ITensorMath.Scale(double alpha, ArraySlice<double> x, ArraySlice<double> y)
        {
            Contract.Requires(x != null);
            Contract.Requires(y != null);
            Contract.Requires(x.Length == y.Length);

            Contract.Requires(!double.IsNaN(alpha));
            Contract.Requires(Contract.ForAll(x, xx => !double.IsNaN(xx)));
            Contract.Requires(Contract.ForAll(y, yy => !double.IsNaN(yy)));
            
            Contract.Ensures(Contract.ForAll(y, yy => !double.IsNaN(yy)));
        }
    }
}
